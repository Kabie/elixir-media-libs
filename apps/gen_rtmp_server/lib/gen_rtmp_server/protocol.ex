defmodule GenRtmpServer.Protocol do
  @moduledoc """
  Ranch protocol that abstracts the RTMP protocol logic away
  """

  @behaviour :ranch_protocol

  alias RtmpSession.Events, as: RtmpEvents
  alias RtmpSession.Messages, as: RtmpMessages

  use GenServer
  require Logger

  defmodule State do
    defstruct socket: nil,
              transport: nil,
              session_id: nil,
              bytes_read: 0,
              bytes_sent: 0,
              handshake_completed: false,
              handshake_instance: nil,
              rtmp_session_instance: nil,
              gen_rtmp_server_adopter: nil,
              adopter_state: nil
  end

  @doc "Starts the protocol for the accepted socket"
  def start_link(ref, socket, transport, [module, options = %GenRtmpServer.RtmpOptions{}]) do
    :proc_lib.start_link(__MODULE__, :init, [ref, socket, transport, module, options])
  end

  def init(ref, socket, transport, module, options) do
    :ok = :proc_lib.init_ack({:ok, self()})
    :ok = :ranch.accept_ack(ref)

    send(self(), {:perform_handshake, module, options})
    :gen_server.enter_loop(__MODULE__, [], %State{socket: socket, transport: transport})
  end

  def handle_info({:perform_handshake, module, initial_options}, state) do
    session_id = UUID.uuid4()
    
    {:ok, {ip, _port}} = :inet.peername(state.socket)
    client_ip_string = ip |> Tuple.to_list() |> Enum.join(".")
        
    _ = Logger.info "#{session_id}: client connected from ip #{client_ip_string}"

    {handshake_instance, %RtmpHandshake.ParseResult{bytes_to_send: bytes_to_send}} 
      = RtmpHandshake.new()

    :ok = state.transport.send(state.socket, bytes_to_send)

    options_list = GenRtmpServer.RtmpOptions.to_keyword_list(initial_options)
    session_config = create_session_config(options_list)    

    new_state = %{state |
      handshake_instance: handshake_instance,
      session_id: session_id,
      rtmp_session_instance: RtmpSession.new(0, session_id, session_config),
      gen_rtmp_server_adopter: module
    }

    set_socket_options(new_state)
    {:noreply, new_state}
  end

  def handle_info({:tcp, _, binary}, state = %State{handshake_completed: false}) do
    case RtmpHandshake.process_bytes(state.handshake_instance, binary) do
      {instance, result = %RtmpHandshake.ParseResult{current_state: :waiting_for_data}} ->
        if byte_size(result.bytes_to_send) > 0, do: state.transport.send(state.socket, result.bytes_to_send)

        new_state = %{state | handshake_instance: instance}
        set_socket_options(new_state)
        {:noreply, new_state}
      
      {instance, result = %RtmpHandshake.ParseResult{current_state: :success}} ->
        if byte_size(result.bytes_to_send) > 0, do: state.transport.send(state.socket, result.bytes_to_send)

        {_, %RtmpHandshake.HandshakeResult{remaining_binary: remaining_binary}}
          = RtmpHandshake.get_handshake_result(instance)

        state = %{state |
          handshake_instance: nil,
          handshake_completed: true  
        }

        {:ok, adopter_state} = state.gen_rtmp_server_adopter.init(state.session_id, get_ip_address(state.socket))

        state = %{state | adopter_state: adopter_state}        
        state = process_binary(state, remaining_binary)

        set_socket_options(state)
        {:noreply, state}
    end    
  end

  def handle_info({:tcp, _, binary}, state = %State{}) do
    state = process_binary(state, binary)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state = %State{}) do
    _ = Logger.info "#{state.session_id}: socket closed" 
    {:stop, :normal, state}
  end

  def handle_info({:rtmp_send, data, send_to_stream_id}, state = %State{}) do
    state = rtmp_send(data, send_to_stream_id, state)
    {:noreply, state}
  end
  
  def handle_info(message, state = %State{}) do
    {:ok, adopter_state} = state.gen_rtmp_server_adopter.handle_message(message, state.adopter_state)
    state = %{state | adopter_state: adopter_state}

    set_socket_options(state) # Just in case
    {:noreply, state}
  end

  def code_change(old_version, state, _) do
    case state.gen_rtmp_server_adopter.code_change(old_version, state.adopter_state) do
      {:ok, new_adopter_state} ->
        state = %{state | adopter_state: new_adopter_state}
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp set_socket_options(state = %State{}) do
    # Ignore the result, as theoretically a tcp closed message should be arriving
    # that will kill this connection
    _ = state.transport.setopts(state.socket, active: :once, packet: :raw)
  end

  defp process_binary(state, binary) do
    {session, results} = RtmpSession.process_bytes(state.rtmp_session_instance, binary)
    state.transport.send(state.socket, results.bytes_to_send)

    {state, session} = handle_event(results.events, state, session)    
    set_socket_options(state)

    %{state | 
      rtmp_session_instance: session,
    }
  end

  defp create_session_config(options) do
    config = %RtmpSession.SessionConfig{}
    config = case Keyword.fetch(options, :fms_version) do
      {:ok, value} -> %{config| fms_version: value}
      :error -> config
    end

    config = case Keyword.fetch(options, :chunk_size) do
      {:ok, value} -> %{config| chunk_size: value}
      :error -> config
    end

    config
  end

  defp get_ip_address(socket) do
    {:ok, {ip, _port}} = :inet.peername(socket)
    ip |> Tuple.to_list() |> Enum.join(".")
  end

  defp handle_event([], state, session) do
    {state, session}
  end

  defp handle_event([event = %RtmpEvents.ConnectionRequested{} | tail], state, session) do
    case state.gen_rtmp_server_adopter.connection_requested(event, state.adopter_state) do
      {:accepted, adopter_state} -> 
        _ = Logger.info("#{state.session_id}: Connection request accepted (app: '#{event.app_name}')")

        state = %{state | adopter_state: adopter_state}
        {session, results} = RtmpSession.accept_request(session, event.request_id)
        state.transport.send(state.socket, results.bytes_to_send)

        {state, session} = handle_event(results.events, state, session)
        handle_event(tail, state, session)

      {{:rejected, command, reason}, adopter_state} ->
        _ = Logger.info("#{state.session_id}: Connection request rejected (app: '#{event.app_name}') - #{reason}")

        case command do
          :disconnect -> state.transport.close(state.socket)
          _ -> :ok
        end

        state = %{state | adopter_state: adopter_state}
        handle_event(tail, state, session)
    end
  end

  defp handle_event([event = %RtmpEvents.PublishStreamRequested{} | tail], state, session) do
    case state.gen_rtmp_server_adopter.publish_requested(event, state.adopter_state) do
      {:accepted, adopter_state} ->
        _ = Logger.info("#{state.session_id}: Publish stream request accepted (app: '#{event.app_name}', key: '#{event.stream_key}')")

        handle_accepted_request(state, session, adopter_state, event.request_id, tail)

      {{:rejected, command, reason}, adopter_state} ->
        _ = Logger.info("#{state.session_id}: Publish stream request rejected (app: '#{event.app_name}', key: '#{event.stream_key}') - #{reason}")

        handle_rejected_request(command, state, session, adopter_state, event.request_id, tail)
    end
  end

  defp handle_event([event = %RtmpEvents.PublishingFinished{} | tail], state, session) do
    {:ok, adopter_state} = state.gen_rtmp_server_adopter.publish_finished(event, state.adopter_state)
    state = %{state | adopter_state: adopter_state}

    handle_event(tail, state, session)
  end

  defp handle_event([%RtmpEvents.PeerChunkSizeChanged{} | tail], state, session) do
    handle_event(tail, state, session)
  end

  defp handle_event([event = %RtmpEvents.AudioVideoDataReceived{} | tail], state, session) do
    {:ok, adopter_state} = state.gen_rtmp_server_adopter.audio_video_data_received(event, state.adopter_state)
    state = %{state | adopter_state: adopter_state}

    handle_event(tail, state, session)
  end

  defp handle_event([event = %RtmpEvents.StreamMetaDataChanged{} | tail], state, session) do
    {:ok, adopter_state} = state.gen_rtmp_server_adopter.metadata_received(event, state.adopter_state)
    state = %{state | adopter_state: adopter_state}

    handle_event(tail, state, session)
  end

  defp handle_event([event = %RtmpEvents.PlayStreamRequested{} | tail], state, session) do
    case state.gen_rtmp_server_adopter.play_requested(event, state.adopter_state) do
      {:accepted, adopter_state} ->
        _ = Logger.info("#{state.session_id}: Play stream request accepted (app: '#{event.app_name}', key: '#{event.stream_key}')")

        handle_accepted_request(state, session, adopter_state, event.request_id, tail)

      {{:rejected, command, reason}, adopter_state} ->
        _ = Logger.info("#{state.session_id}: Play stream request rejected (app: '#{event.app_name}', key: '#{event.stream_key}') - #{reason}")

        handle_rejected_request(command, state, session, adopter_state, event.request_id, tail)
    end
  end

  defp handle_event([event = %RtmpEvents.PlayStreamFinished{} | tail], state, session) do
    {:ok, adopter_state} = state.gen_rtmp_server_adopter.play_finished(event, state.adopter_state)
    state = %{state | adopter_state: adopter_state}

    handle_event(tail, state, session)
  end

  defp handle_event([event | tail], state, session) do
    _ = Logger.warn("#{state.session_id}: No code to handle RTMP session event of type #{inspect(event)}")
    handle_event(tail, state, session)
  end

  defp handle_accepted_request(state, session, new_adopter_state, request_id, remaining_events) do
    state = %{state | adopter_state: new_adopter_state}
    {session, results} = RtmpSession.accept_request(session, request_id)
    state.transport.send(state.socket, results.bytes_to_send)

    {state, session} = handle_event(results.events, state, session)
    handle_event(remaining_events, state, session)
  end

  defp handle_rejected_request(command, state, session, new_adopter_state, _request_id, remaining_events) do
    case command do
      :disconnect -> state.transport.close(state.socket)
      _ -> :ok
    end

    state = %{state | adopter_state: new_adopter_state}
    handle_event(remaining_events, state, session)
  end

  defp rtmp_send(data, send_to_stream_id, state) do
    message = form_outbound_rtmp_message(data)

    {session, results} = RtmpSession.send_rtmp_message(state.rtmp_session_instance, send_to_stream_id, message)
    state.transport.send(state.socket, results.bytes_to_send)

    # There shouldn't be any events to handle since we are just sending a message
    set_socket_options(state)
    %{state | rtmp_session_instance: session}
  end

  defp form_outbound_rtmp_message(av_data = %GenRtmpServer.AudioVideoData{}) do
    case av_data.data_type do
      :audio -> %RtmpMessages.AudioData{data: av_data.data}
      :video -> %RtmpMessages.VideoData{data: av_data.data}
    end
  end

  defp form_outbound_rtmp_message(%GenRtmpServer.MetaData{details: metadata}) do
    %RtmpMessages.Amf0Data{parameters: [
      "onMetaData",
      %{
        "width" => metadata.video_width,
        "height" => metadata.video_height,
        "framerate" => metadata.video_frame_rate,
        "videocodecid" => metadata.video_codec,
        "audiocodecid" => metadata.audio_codec,
        "audiochannels" => metadata.audio_channels,
        "audiodatarate" => metadata.audio_bitrate_kbps,
        "audiosamplerate" => metadata.audio_sample_rate,
        "videodatarate" => metadata.video_bitrate_kbps
      }
    ]}
  end

  defp form_outbound_rtmp_message(data) do
    raise("No known way to form outbound rtmp message for data: #{inspect(data)}")
  end

end