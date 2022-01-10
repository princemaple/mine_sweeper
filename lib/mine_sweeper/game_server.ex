defmodule MineSweeper.GameServer do
  use GenServer, restart: :temporary

  require Logger

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    name = if name, do: [name: name], else: []
    GenServer.start(__MODULE__, opts, name)
  end

  def dimension(server) do
    GenServer.call(server, :dimension)
  end

  def field(server) do
    GenServer.call(server, :field)
  end

  @impl true
  def init(opts) do
    {slug, opts} = Keyword.pop(opts, :slug)
    {visibility, opts} = Keyword.pop(opts, :visibility)

    Registry.register(RealmRegistry, visibility, slug)
    Registry.register(GameRegistry, {:game, slug}, [])

    {:ok, %{opts: opts, slug: slug}, {:continue, :init_game}}
  end

  @impl true
  def handle_continue(:init_game, state) do
    Logger.debug(init: state.slug, opts: state.opts)

    width = state.opts[:width] || 10
    height = state.opts[:height] || 8
    count = state.opts[:count] || 10

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
      MineSweeper.CellServer.start_link({state.slug, {coords, data}})
    end

    {:noreply,
     %{state | opts: Keyword.merge(state.opts, width: width, height: height, count: count)}}
  end

  @impl true
  def handle_call(:dimension, _from, %{opts: opts} = state) do
    {:reply, {opts[:width], opts[:height]}, state}
  end

  @impl true
  def handle_call(:field, _from, %{opts: opts} = state) do
    {:reply, {opts[:width], opts[:height]}, state}
  end
end
