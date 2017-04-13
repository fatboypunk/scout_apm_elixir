defmodule ScoutApm.Instruments.EctoLogger do
  # [info] Entry:
  # %Ecto.LogEntry{
    # ansi_color: nil,
    # connection_pid: nil,
    # decode_time: 16000,
    # params: [],
    # query: "SELECT u0.\"id\", u0.\"name\", u0.\"age\" FROM \"users\" AS u0",
    # query_time: 1192999,
    # queue_time: 36000,
    # result: {:ok,
    #    %Postgrex.Result{
    #      columns: ["id", "name", "age"], 
    #      command: :select,
    #      connection_id: 70629,
    #      num_rows: 1, 
    #      rows: [[%TestappPhoenix.User{__meta__: #Ecto.Schema.Metadata<:loaded, "users">, age: 32, id: 1, name: "chris"}]]}
   #      },
    # source: "users"}
  def log(entry) do
    record(entry)
    entry
  end

  defp record(entry) do
    ScoutApm.TrackedRequest.track_layer(
      "Ecto",
      query_name(entry),
      query_time(entry),
      fn layer ->
        layer
        |> ScoutApm.Internal.Layer.update_desc(entry.query)
      end
    )
  end

  def query_name(entry) do
    case entry do
      nil -> "Unknown"
      _ ->
        command = case entry.result do
          {:ok, result} -> result.command
          _ -> "Unknown"
        end

        table = entry.source

        "#{command}##{table}"
    end
  end

  def query_time(entry) do
    raw_time = entry.query_time
    microtime = System.convert_time_unit(raw_time, :native, :microseconds)
    ScoutApm.Internal.Duration.new(microtime, :microseconds)
  end
end
