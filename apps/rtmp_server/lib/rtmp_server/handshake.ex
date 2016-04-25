defmodule RtmpServer.Handshake do 
  require Logger
  
  @doc "Processes a handshake for a new rtmp connection"
  def process(socket, transport) do
      with {:ok, _} <- receive_c0(socket, transport),
           :ok <- send_s0(socket, transport),
           {:ok, sent_details} <- send_s1(socket, transport),
           {:ok, received_details} <- receive_c1(socket, transport),
           :ok <- send_s2(socket, transport, received_details),
           :ok <- receive_c2(socket, transport, sent_details),
           do: :ok
  end
  
  defp receive_c0(socket, transport) do   
    with {:ok, byte} <- transport.recv(socket, 1, 5000),
          do: validate_c0(byte)
  end
  
  defp validate_c0(byte) when byte < <<32>>, do: :ok
  defp validate_c0(byte), do: {:error, :bad_c0}
  
  defp receive_c1(socket, transport) do
    with {:ok, bytes} <- transport.recv(socket, 1536, 5000),
          do: transform_c1(bytes)
  end
  
  defp transform_c1(bytes) do
    <<time::8 * 4, zeros::8 * 4, random::binary-size(1528)>> = bytes
        
    Logger.debug "c1 received"
    {:ok, %RtmpServer.Handshake.Details{time: time, random_data: random}}
  end
  
  defp receive_c2(socket, transport, sent_details) do
    with {:ok, bytes} <- transport.recv(socket, 1536, 5000),
          do: validate_c2(bytes, sent_details)
  end
  
  defp validate_c2(bytes, sent_details) do
    <<time1::8 * 4, time2::8 * 4, random_echo::binary-size(1528)>> = bytes
    if (time1 == sent_details.time) && (random_echo == sent_details.random_data) do
      Logger.debug "c2 received"
      :ok
    else
      Logger.debug "Time: #{inspect(time1)} / #{inspect(sent_details.time)}"
      Logger.debug "random: #{inspect(random_echo)} / #{inspect(sent_details.random_data)}"
      
      {:error, :value_mismatch}
    end
  end
  
  defp send_s0(socket, transport) do
    transport.send(socket, <<3>>)
  end
  
  defp send_s1(socket, transport) do
    time = 0
    zeros = <<0::8 * 4>>
    random = generate_random_binary(1528, <<>>)
    
    with :ok <- transport.send(socket, <<time::8 * 4>> <> zeros <> random),
         do: {:ok, %RtmpServer.Handshake.Details{time: time, random_data: random}}
  end
  
  defp send_s2(socket, transport, received_details) do
    time1 = <<received_details.time::8 * 4>>
    time2 = <<0::8 * 4>>
    random = received_details.random_data
    
    transport.send(socket, time1 <> time2 <> random)
  end
  
  defp generate_random_binary(0, accumulator), do: accumulator
  defp generate_random_binary(count, accumulator), do: generate_random_binary(count - 1,  accumulator <> <<:random.uniform(254)>> )
  
end