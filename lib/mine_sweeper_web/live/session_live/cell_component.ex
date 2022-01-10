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

  def show(%{revealed?: true, value: :mine}), do: "💣"
  def show(%{revealed?: true, value: 0}), do: " "
  def show(%{revealed?: true, value: v}), do: v
  def show(%{revealed?: false, marked?: true}), do: "🚩"
  def show(%{revealed?: false}), do: " "

  @color List.to_tuple(~w(
           text-transparent
           text-blue-600
           text-green-600
           text-red-600
           text-purple-600
           text-red-900
           text-teal-400
           text-black-600
           text-gray-600
           ))
  def class(%{revealed?: revealed?, marked?: marked?, value: value}) do
    [
      marked? && "bg-yellow-200",
      revealed? && "bg-blue-200",
      revealed? && value == :mine && "bg-red-200",
      revealed? && value == 0 && "bg-gray-100",
      is_integer(value) && elem(@color, value)
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end
end
