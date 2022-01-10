defmodule MineSweeperWeb.PageController do
  use MineSweeperWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/sessions")
  end
end
