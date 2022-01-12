defmodule MineSweeperWeb.SessionLive.CellComponent do
  use MineSweeperWeb, :live_component

  alias MineSweeper.CellServer

  @impl true
  def update(%{slug: slug, coords: coords}, socket) do
    cell = CellServer.get(CellServer.via(slug, coords))

    {:ok,
     socket
     |> assign(:slug, slug)
     |> assign(:coords, coords)
     |> assign(:cell, cell)}
  end

  @impl true
  def handle_event("reveal", _payload, %{assigns: %{slug: slug, coords: coords}} = socket) do
    cell = CellServer.reveal(CellServer.via(slug, coords))
    {:noreply, socket |> assign(:cell, cell)}
  end

  @impl true
  def handle_event("mark", _payload, %{assigns: %{slug: slug, coords: coords}} = socket) do
    cell = CellServer.mark(CellServer.via(slug, coords))
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
  def class(%{revealed?: revealed?, marked?: marked?, opaque?: opaque?, value: value}) do
    [
      !revealed? && "bg-gray-200",
      revealed? && "cursor-default",
      revealed? && "bg-blue-200",
      revealed? && value == :mine && "bg-red-200",
      revealed? && value == 0 && "bg-gray-100",
      marked? && "bg-yellow-200",
      opaque? && "blur-sm",
      is_integer(value) && elem(@color, value)
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end
end
