defmodule MineSweeper.CellServer do
  use GenServer, restart: :temporary

  require Logger

  def start_link({slug, {coords, _}} = data) do
    GenServer.start(__MODULE__, data,
      name: {:via, Registry, {GameRegistry, {:cell, slug, coords}}}
    )
  end

  def get(cell) do
    GenServer.call(cell, :get)
  end

  def reveal(cell) do
    GenServer.call(cell, :reveal)
  end

  def mark(cell) do
    GenServer.call(cell, :mark)
  end

  def detect(cell) do
    GenServer.call(cell, :detect)
  end

  @impl true
  def init({slug, {coords, data}}) do
    {:ok, %{slug: slug, coords: coords, data: data}}
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
    data = %{state.data | marked?: !state.data.marked?}
    update(state, data)
    {:reply, data, %{state | data: data}}
  end

  @impl true
  def handle_call(:reveal, _from, %{data: %{revealed?: true}} = state) do
    {:reply, state.data, state}
  end

  @impl true
  def handle_call(:reveal, _from, state) do
    data = do_reveal(state)
    {:reply, data, %{state | data: data}}
  end

  @impl true
  def handle_call(:detect, _from, state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_info(:reveal, %{data: %{marked?: true}} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:reveal, %{data: %{revealed?: true}} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:reveal, state) do
    data = do_reveal(state)
    {:noreply, %{state | data: data}}
  end

  defp do_reveal(state) do
    data = %{state.data | revealed?: true}
    {row, col} = state.coords

    update(state, data)

    if data.value == 0 do
      for dr <- -1..1//1, dc <- -1..1//1 do
        pid = Registry.whereis_name({GameRegistry, {:cell, state.slug, {row + dr, col + dc}}})
        Process.send_after(pid, :reveal, 30)
      end
    end

    data
  end

  defp update(state, data) do
    Phoenix.PubSub.broadcast(MineSweeper.PubSub, state.slug, {:update, state.coords, data})
  end
end
