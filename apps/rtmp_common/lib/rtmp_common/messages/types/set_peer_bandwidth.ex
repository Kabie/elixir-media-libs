defmodule RtmpCommon.Messages.Types.SetPeerBandwidth do
  @moduledoc """
  
  Sender is requesting the receiver limit its output
  bandwidth by limiting the amount of sent but
  unacknowledged data to the specified window size
  
  """
  
  defstruct window_size: 0, limit_type: nil
  
  @behaviour RtmpCommon.Messages.Message
  
  def parse(data) do
    <<size::32, type::8>> = data
    
    %__MODULE__{window_size: size, limit_type: get_friendly_type(type)}
  end
  
  defp get_friendly_type(0), do: :hard
  defp get_friendly_type(1), do: :soft
  defp get_friendly_type(2), do: :dynamic
end