defmodule RtmpCommon.Messages.HandlerTest do
  use ExUnit.Case, async: true
  alias RtmpCommon.Messages.Types, as: Types
  alias RtmpCommon.Messages, as: Messages
  alias RtmpCommon.Amf0, as: Amf0
  
  setup do
    {handler, _} =
      RtmpCommon.Messages.Handler.new("abc")
      |> RtmpCommon.Messages.Handler.get_responses()
      
    {:ok, handler: handler}
  end
  
  test "New handler queues up initial responses" do
    {_, [message1, message2, message3]} =
      RtmpCommon.Messages.Handler.new("abc")
      |> RtmpCommon.Messages.Handler.get_responses()
      
    window_message = Enum.find([message1, message2, message3], 
      fn(x) -> match?(%Messages.Response{message: %Types.WindowAcknowledgementSize{}}, x) end
    )      
      
    bandwidth_message = Enum.find([message1, message2, message3], 
      fn(x) -> match?(%Messages.Response{message: %Types.SetPeerBandwidth{}}, x) end
    )
    
    chunk_size_message = Enum.find([message1, message2, message3], 
      fn(x) -> match?(%Messages.Response{message: %Types.SetChunkSize{}}, x) end
    )
    
    assert %Messages.Response{
      stream_id: 0,
      message: %Types.WindowAcknowledgementSize{}
    } = window_message
    
    assert %Messages.Response{
      stream_id: 0,
      message: %Types.SetPeerBandwidth{}
    } = bandwidth_message
    
    assert %Messages.Response{
      stream_id: 0,
      message: %Types.SetChunkSize{}
    } = chunk_size_message
  end
  
  test "Getting responses clears response state" do
    {handler, _} =
      RtmpCommon.Messages.Handler.new("abc")
      |> RtmpCommon.Messages.Handler.get_responses()
      
      assert {_, []} = RtmpCommon.Messages.Handler.get_responses(handler)
  end
  
  test "Ack response queued when byte received value over window", %{handler: handler} do
    ack_size = %Types.WindowAcknowledgementSize{size: 5000}
    
    {_, [message]} =
      RtmpCommon.Messages.Handler.handle(handler, ack_size)
      |> RtmpCommon.Messages.Handler.set_bytes_received(5001)
      |> RtmpCommon.Messages.Handler.get_responses()
      
    assert %Messages.Response{
      stream_id: 0,
      message: %Types.Acknowledgement{sequence_number: 5001}
    } = message
  end
  
  test "No Ack response queued when byte received under window", %{handler: handler} do
    ack_size = %RtmpCommon.Messages.Types.WindowAcknowledgementSize{size: 5000}
    
    {_, []} =
      RtmpCommon.Messages.Handler.handle(handler, ack_size)
      |> RtmpCommon.Messages.Handler.set_bytes_received(4999)
      |> RtmpCommon.Messages.Handler.get_responses()
  end
  
  test "Connect message returns response", %{handler: handler} do
    message = %Types.Amf0Command{
      command_name: "connect",
      transaction_id: 1,
      command_object: %Amf0.Object{type: :object, value: %{
        "app" => %Amf0.Object{type: :string, value: "myapp"}
      }}
    }
    
    {_, [message]} =
      RtmpCommon.Messages.Handler.handle(handler, message)
      |> RtmpCommon.Messages.Handler.get_responses()
      
    assert %Messages.Response{
      stream_id: 0,
      message: %Types.Amf0Command{
        command_name: "_result",
        transaction_id: 1,
        command_object: %Amf0.Object{
            type: :object,
            value: %{
              "fmsVer" => %Amf0.Object{type: :string, value: <<_::binary>>},
              "capabilities" => %Amf0.Object{type: :number, value: 31}
            } 
          },
        additional_values: [
          %Amf0.Object{
            type: :object,
            value: %{
              "level" => %Amf0.Object{type: :string, value: "status"},
              "code" => %Amf0.Object{type: :string, value: "NetConnection.Connect.Success"},
              "description" => %Amf0.Object{type: :string, value: "Connection succeeded"},
              "objectEncoding" => %Amf0.Object{type: :number, value: 0}
            }
          }
        ]
      }
    } = message
  end
end