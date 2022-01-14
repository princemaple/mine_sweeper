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

  def info(server) do
    GenServer.call(server, :info)
  end

  def time_limit(server) do
    GenServer.call(server, :time_limit)
  end

  def mark(server, diff) do
    GenServer.cast(server, {:mark, diff})
  end

  def reveal(server) do
    GenServer.cast(server, :reveal)
  end

  def explode(server) do
    GenServer.cast(server, :explode)
  end

  @impl true
  def init(opts) do
    {slug, opts} = Keyword.pop(opts, :slug)
    {visibility, opts} = Keyword.pop(opts, :visibility)
    {time_limit, opts} = Keyword.pop(opts, :time_limit)

    Registry.register(RealmRegistry, visibility, slug)

    {:ok,
     %{
       opts: opts,
       slug: slug,
       time: 0,
       mark_count: 0,
       reveal_count: 0,
       time_limit: time_limit,
       timer_ref: nil,
       cells_sup: nil,
       mines: nil
     }, {:continue, :init_game}}
  end

  @impl true
  def handle_continue(:init_game, state) do
    Logger.debug(init: state.slug, opts: state.opts)

    {:noreply,
     state
     |> setup_field()
     |> setup_timer()}
  end

  defp setup_field(state) do
    slug = state.slug
    width = Keyword.fetch!(state.opts, :width)
    height = Keyword.fetch!(state.opts, :height)
    mine_count = Keyword.fetch!(state.opts, :mine_count)

    field =
      for row <- 1..height, col <- 1..width do
        {{row, col}, %{revealed?: false, marked?: false, value: 0}}
      end

    {mines, cells} =
      field
      |> Enum.shuffle()
      |> Enum.split(mine_count)

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

    {:ok, cells_sup} =
      DynamicSupervisor.start_child(GameSupervisor, {DynamicSupervisor, strategy: :one_for_one})

    for {coords, opts} <- field do
      DynamicSupervisor.start_child(cells_sup, {MineSweeper.CellServer, {slug, {coords, opts}}})
    end

    %{state | cells_sup: cells_sup, mines: Enum.map(mines, &elem(&1, 0))}
  end

  defp setup_timer(state) do
    {:ok, ref} = :timer.send_interval(1000, self(), :tick)
    %{state | timer_ref: ref}
  end

  @impl true
  def handle_call(:info, _from, %{opts: opts} = state) do
    {:reply,
     {
       {opts[:width], opts[:height]},
       state.time,
       {state.mark_count, opts[:mine_count]}
     }, state}
  end

  @impl true
  def handle_call(:time_limit, _from, state) do
    {:reply, state.time_limit, state}
  end

  @impl true
  def handle_cast({:mark, diff}, state) do
    mark_count = state.mark_count + diff
    Phoenix.PubSub.broadcast(MineSweeper.PubSub, state.slug, {:mark_count, mark_count})
    {:noreply, %{state | mark_count: mark_count}}
  end

  @impl true
  def handle_cast(:reveal, state) do
    reveal_count = state.reveal_count + 1

    if state.opts[:width] * state.opts[:height] - state.opts[:mine_count] == reveal_count do
      Phoenix.PubSub.broadcast(MineSweeper.PubSub, state.slug, :win)
      {:stop, :shutdown, %{state | reveal_count: reveal_count}}
    else
      {:noreply, %{state | reveal_count: reveal_count}}
    end
  end

  @impl true
  def handle_cast(:explode, state) do
    Phoenix.PubSub.broadcast(MineSweeper.PubSub, state.slug, :lose)

    state.mines
    |> Enum.with_index()
    |> Enum.each(fn {coords, i} ->
      Task.start(fn ->
        Process.sleep(100 * i)
        MineSweeper.CellServer.reveal(MineSweeper.CellServer.via(state.slug, coords))
      end)
    end)

    {:stop, :shutdown, state}
  end

  @impl true
  def handle_info(:tick, state) do
    time = state.time + 1
    Phoenix.PubSub.broadcast(MineSweeper.PubSub, state.slug, {:tick, time})

    if time < state.time_limit do
      {:noreply, %{state | time: time}}
    else
      {:stop, :shutdown, %{state | time: time}}
    end
  end

  @impl true
  def terminate(:shutdown, state) do
    :timer.cancel(state.timer_ref)
    :timer.kill_after(15_000, state.cells_sup)
  end
end
