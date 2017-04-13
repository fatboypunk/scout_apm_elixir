defmodule ScoutApm.Internal.Layer do
  @type t :: %__MODULE__{
    type: String.t,
    name: nil | String.t,
    desc: nil | String.t,
    backtrace: nil | list(any()),
    uri: nil | String.t,
    started_at: number(),
    stopped_at: nil | Integer,
    manual_duration: ScoutApm.Internal.Duration.t,
    children: list(%__MODULE__{})
  }

  defstruct [
   :type,
   :name,
   :desc,
   :backtrace,
   :uri,
   :children,
   :started_at,
   :stopped_at,

   # If this is set, ignore started_at -> stopped_at valuse when calculating
   # how long this layer ran
   :manual_duration,
   ]

  alias ScoutApm.Internal.Duration

  ##################
  #  Construction  #
  ##################

  @spec new(map) :: __MODULE__.t
  def new(%{type: type, name: name, started_at: started_at}) do
    %__MODULE__{type: type, name: name, desc: nil, backtrace: nil, started_at: started_at, children: []}
  end
  def new(%{type: type, started_at: started_at}) do
    %__MODULE__{type: type, name: nil, desc: nil, backtrace: nil, started_at: started_at, children: []}
  end
  def new(%{type: type, name: name}) do
    started_at = System.monotonic_time(:microseconds)
    %__MODULE__{type: type, name: name, desc: nil, backtrace: nil, started_at: started_at, children: []}
  end
  def new(%{type: type}) do
    started_at = System.monotonic_time(:microseconds)
    %__MODULE__{type: type, name: nil, desc: nil, backtrace: nil, started_at: started_at, children: []}
  end

  #######################
  #  Updater Functions  #
  #######################

  # Don't update a name to become nil
  def update_name(layer, nil), do: layer
  def update_name(layer, name), do: %{layer | name: name}

  def update_stopped_at(layer), do: update_stopped_at(layer, System.monotonic_time(:microseconds))
  def update_stopped_at(layer, stopped_at) do
    %{layer | stopped_at: stopped_at}
  end

  def update_children(layer, children) do
    %{layer | children: children}
  end

  def update_desc(layer, desc) do
    %{layer | desc: desc}
  end

  def update_backtrace(layer, backtrace) do
    %{layer | backtrace: backtrace}
  end

  def update_uri(layer, uri) do
    %{layer | uri: uri}
  end

  def set_manual_duration(layer, %Duration{}=duration) do
    %{layer | manual_duration: duration}
  end

  #############
  #  Queries  #
  #############

  def total_time(layer) do
    case layer.manual_duration do
      nil ->
        Duration.new(layer.stopped_at - layer.started_at, :microseconds)
      %Duration{} ->
        layer.manual_duration
    end
  end

  def total_child_time(layer) do
    Enum.reduce(layer.children, Duration.zero(),
      fn(child, acc) ->
        Duration.add(acc, total_time(child))
      end)
  end

  def total_exclusive_time(layer) do
    Duration.subtract(total_time(layer), total_child_time(layer))
  end
end
