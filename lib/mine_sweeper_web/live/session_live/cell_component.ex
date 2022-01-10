defmodule MineSweeperWeb.SessionLive.CellComponent do
  use MineSweeperWeb, :live_component

  alias MineSweeper.{Game, CellServer}

  @impl true
  def update(%{slug: slug, coords: coords}, socket) do
    cell_server = Game.get_cell!(slug, coords)
    cell = CellServer.get(cell_server)

    {:ok,
     socket
     |> assign(:slug, slug)
     |> assign(:coords, coords)
     |> assign(:cell, cell)
     |> assign(:cell_server, cell_server)}
  end

  @impl true
  def handle_event("reveal", _payload, socket) do
    cell = CellServer.reveal(socket.assigns.cell_server)
    {:noreply, socket |> assign(:cell, cell)}
  end

  @impl true
  def handle_event("mark", _payload, socket) do
    cell = CellServer.mark(socket.assigns.cell_server)
    {:noreply, socket |> assign(:cell, cell)}
  end

  @impl true
  def handle_event(
        "detect",
        _payload,
        %{assigns: %{cell: %{revealed?: true, value: value}}} = socket
      )
      when is_integer(value) and value > 0 do
    {:noreply, socket}
  end

  @impl true
  def handle_event("detect", _payload, socket) do
    {:noreply, socket}
  end

  def show(%{revealed?: true, value: :mine}) do
    "💣"
  end

  def show(%{revealed?: true, value: 0}) do
    " "
  end

  def show(%{revealed?: true, value: v}) do
    v
  end

  def show(%{revealed?: false, marked?: true}) do
    "🚩"
  end

  def show(%{revealed?: false}) do
    " "
  end
end
