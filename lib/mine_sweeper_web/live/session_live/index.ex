defmodule MineSweeperWeb.SessionLive.Index do
  use MineSweeperWeb, :live_view

  alias MineSweeper.Game

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :sessions, list_sessions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Session")
    |> assign(:session, %{id: nil})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Sessions")
    |> assign(:session, nil)
  end

  defp list_sessions do
    Game.list_sessions()
  end
end
