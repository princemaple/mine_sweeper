defmodule MineSweeperWeb.SessionLive.Show do
  use MineSweeperWeb, :live_view

  alias MineSweeper.Game

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:session, Game.get_session!(id))
     |> assign(:id, id)}
  end

  defp page_title(:show), do: "Game Session"
end
