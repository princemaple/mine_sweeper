defmodule MineSweeper.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MineSweeperWeb.Telemetry,
      {Phoenix.PubSub, name: MineSweeper.PubSub},
      {Registry, name: RealmRegistry, keys: :duplicate},
      {Registry, name: GameRegistry, keys: :unique},
      {DynamicSupervisor, strategy: :one_for_one, name: GameSupervisor},
      MineSweeperWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MineSweeper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MineSweeperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
