defmodule RtmpCommon.Messages.Message do
  @callback parse(binary) :: any
  @callback serialize(struct()) :: {:ok, %RtmpCommon.Messages.SerializedMessage{}}
  @callback get_default_chunk_stream_id(struct()) :: pos_integer()
end