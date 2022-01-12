defmodule MineSweeperWeb.SessionLive.Show do
  use MineSweeperWeb, :live_view

  alias MineSweeper.{Game, GameServer}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:time, nil)}
  end

  @impl true
  def handle_params(%{"id" => slug}, _, socket) do
    session = Game.get_session!(slug)

    Phoenix.PubSub.subscribe(MineSweeper.PubSub, slug)

    {width, height} = GameServer.dimension(session)
    time_limit = GameServer.time_limit(session)

    {:noreply,
     socket
     |> assign(:session, session)
     |> assign(:width, width)
     |> assign(:height, height)
     |> assign(:slug, slug)
     |> assign(:page_title, slug)
     |> assign(:buster, %{})
     |> assign(:time_limit, Time.from_seconds_after_midnight(time_limit))}
  end

  @impl true
  def handle_info({:update, coords}, socket) do
    {:noreply, assign(socket, :buster, Map.update(socket.assigns.buster, coords, 1, &(&1 + 1)))}
  end

  @impl true
  def handle_info({:tick, time}, socket) do
    {:noreply, assign(socket, :time, Time.from_seconds_after_midnight(time))}
  end
end
