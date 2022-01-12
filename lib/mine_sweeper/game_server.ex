defmodule MineSweeper.GameServer do
  use GenServer, restart: :temporary

  require Logger

  def via(slug) do
    {:via, Registry, {GameRegistry, {:game, slug}}}
  end

  def start_link(opts) do
    slug = Keyword.fetch!(opts, :slug)
    GenServer.start_link(__MODULE__, opts, name: via(slug))
  end

  def dimension(server) do
    GenServer.call(server, :dimension)
  end

  def time_limit(server) do
    GenServer.call(server, :time_limit)
  end

  def hide(server) do
    GenServer.call(server, :hide)
  end

  @impl true
  def init(opts) do
    {slug, opts} = Keyword.pop(opts, :slug)
    {visibility, opts} = Keyword.pop(opts, :visibility)
    {time_limit, opts} = Keyword.pop(opts, :time_limit)

    Registry.register(RealmRegistry, visibility, slug)

    {:ok, %{opts: opts, slug: slug, time: 0, time_limit: time_limit}, {:continue, :init_game}}
  end

  @impl true
  def handle_continue(:init_game, state) do
    Logger.debug(init: state.slug, opts: state.opts)

    width = state.opts[:width]
    height = state.opts[:height]
    count = state.opts[:count]

    setup_field(state.slug, width, height, count)
    setup_timer()

    {:noreply,
     %{state | opts: Keyword.merge(state.opts, width: width, height: height, count: count)}}
  end

  defp setup_field(slug, width, height, count) do
    field =
      for row <- 1..height, col <- 1..width do
        {{row, col}, %{revealed?: false, marked?: false, value: 0}}
      end

    {mines, cells} =
      field
      |> Enum.shuffle()
      |> Enum.split(count)

    field =
      mines
      |> Enum.map(fn {coords, cell} -> {coords, %{cell | value: :mine, marked?: false}} end)
      |> Kernel.++(cells)
      |> Enum.into(%{})

    field =
      Enum.reduce(mines, field, fn {{row, col}, _}, field ->
        for dr <- -1..1//1,
            dc <- -1..1//1,
            coords = {row + dr, col + dc},
            is_map_key(field, coords),
            reduce: field do
          field ->
            Map.replace(
              field,
              coords,
              Map.update!(field[coords], :value, fn
                :mine -> :mine
                n -> n + 1
              end)
            )
        end
      end)

    for {coords, data} <- field do
      MineSweeper.CellServer.start_link({slug, {coords, data}})
    end
  end

  defp setup_timer do
    :timer.send_interval(1000, self(), :tick)
  end

  @impl true
  def handle_call(:dimension, _from, %{opts: opts} = state) do
    {:reply, {opts[:width], opts[:height]}, state}
  end

  @impl true
  def handle_call(:time_limit, _from, state) do
    {:reply, state.time_limit, state}
  end

  @impl true
  def handle_call(:hide, _from, state) do
    Registry.unregister(RealmRegistry, :public)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    time = state.time + 1
    Phoenix.PubSub.broadcast(MineSweeper.PubSub, state.slug, {:tick, time})

    if time < state.time_limit do
      {:noreply, %{state | time: time}}
    else
      {:stop, :normal, %{state | time: time}}
    end
  end
end
