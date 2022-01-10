defmodule MineSweeperWeb.SessionLive.Show do
  use MineSweeperWeb, :live_view

  alias MineSweeper.{Game, GameServer}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => slug}, _, socket) do
    session = Game.get_session!(slug)

    Phoenix.PubSub.subscribe(MineSweeper.PubSub, slug)

    {width, height} = GameServer.dimension(session)

    {:noreply,
     socket
     |> assign(:session, session)
     |> assign(:width, width)
     |> assign(:height, height)
     |> assign(:slug, slug)
     |> assign(:page_title, slug)
     |> assign(:buster, %{})}
  end

  @impl true
  def handle_info({:update, coords, data}, socket) do
    {:noreply, assign(socket, :buster, Map.put(socket.assigns.buster, coords, data))}
  end
end
