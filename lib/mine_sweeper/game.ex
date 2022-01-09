defmodule MineSweeper.Game do
  @moduledoc """
  The Game context.
  """

  def list_sessions do
    Registry.lookup(RealmRegistry, :public)
  end

  def get_session!(slug) do
    [game] = Registry.lookup(GameRegistry, slug)
    game
  end

  def create_session(%{"slug" => slug, "password" => password}) do
    MineSweeper.GameServer.start_link(slug: slug, password: password)
  end
end
