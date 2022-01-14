defmodule MineSweeper.CellServer do
  use GenServer, restart: :temporary

  alias MineSweeper.GameServer
  require Logger

  def via(slug, coords) do
    {:via, Registry, {GameRegistry, {:cell, slug, coords}}}
  end

  def start_link({slug, {coords, _}} = data) do
    GenServer.start_link(__MODULE__, data, name: via(slug, coords))
  end

  def get(cell) do
    GenServer.call(cell, :get)
  end

  def reveal(cell) do
    GenServer.call(cell, :reveal)
  end

  defp reveal(cell, :chain) do
    GenServer.cast(cell, :chain)
  end

  defp reveal(cell, :death) do
    GenServer.cast(cell, :death)
  end

  def mark(cell) do
    GenServer.call(cell, :mark)
  end

  def detect(cell) do
    GenServer.call(cell, :detect)
  end

  @impl true
  def init({slug, {coords, data}}) do
    {:ok, %{slug: slug, coords: coords, data: Map.put(data, :opaque?, false)}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state.data, state}
  end

  @impl true
  def handle_call(:mark, _from, %{data: %{revealed?: true}} = state) do
    {:reply, state.data, state}
  end

  @impl true
  def handle_call(:mark, _from, state) do
    broadcast_update(state)

    if state.data.marked? do
      MineSweeper.GameServer.mark(GameServer.via(state.slug), -1)
    else
      MineSweeper.GameServer.mark(GameServer.via(state.slug), 1)
    end

    data = %{state.data | marked?: !state.data.marked?}
    {:reply, data, %{state | data: data}}
  end

  @impl true
  def handle_call(:reveal, _from, %{data: %{revealed?: true}} = state) do
    {:reply, state.data, state}
  end

  @impl true
  def handle_call(:reveal, _from, state) do
    data = do_reveal(state, :chain)

    if state.data.marked? do
      MineSweeper.GameServer.mark(GameServer.via(state.slug), -1)
    end

    {:reply, data, %{state | data: data}}
  end

  @impl true
  def handle_call(:detect, _from, state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_cast(:chain, %{data: %{marked?: true}} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(type, %{data: %{revealed?: true}} = state) when type in [:chain, :death] do
    {:noreply, state}
  end

  @impl true
  def handle_cast(type, state) when type in [:chain, :death] do
    data = do_reveal(state, type)
    {:noreply, %{state | data: data}}
  end

  defp do_reveal(state, type) do
    broadcast_update(state)

    case {type, state.data.value} do
      {:chain, 0} ->
        Task.start(fn ->
          Process.sleep(30)
          chain(state, :chain)
        end)

        %{state.data | revealed?: true, marked?: false}

      {:chain, :mine} ->
        Task.start(fn ->
          Process.sleep(30)
          chain(state, :death)
        end)

        Task.start(fn ->
          MineSweeper.GameServer.exit(GameServer.via(state.slug))
        end)

        %{state.data | revealed?: true, marked?: false}

      {:death, _} ->
        Task.start(fn ->
          Process.sleep(30)
          chain(state, :death)
        end)

        %{state.data | revealed?: true, opaque?: true}

      {:chain, _n} ->
        %{state.data | revealed?: true, marked?: false}

      _ ->
        %{state.data | revealed?: false}
    end
  end

  defp chain(state, type) do
    {row, col} = state.coords

    for dr <- -1..1//1, dc <- -1..1//1 do
      reveal(via(state.slug, {row + dr, col + dc}), type)
    end
  end

  defp broadcast_update(state) do
    Phoenix.PubSub.broadcast(MineSweeper.PubSub, state.slug, {:update, state.coords})
  end
end
