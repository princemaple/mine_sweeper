defmodule MineSweeperWeb.Router do
  use MineSweeperWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MineSweeperWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MineSweeperWeb do
    pipe_through :browser

    get "/", PageController, :index

    live "/sessions", SessionLive.Index, :index
    live "/sessions/new", SessionLive.Index, :new
    live "/sessions/:id", SessionLive.Show, :show
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MineSweeperWeb.Telemetry
    end
  end
end
