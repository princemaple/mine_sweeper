defmodule MineSweeper.Game do
  @moduledoc """
  The Game context.
  """

  def list_sessions do
    Registry.lookup(RealmRegistry, :public)
  end

  def get_session!(slug) do
    Registry.whereis_name({GameRegistry, {:game, slug}})
  end

  @difficulty %{
    "easy" => {10, 8, 10},
    "medium" => {18, 14, 40},
    "hard" => {24, 20, 99}
  }

  def create_session(%{
        "slug" => slug,
        "password" => password,
        "difficulty" => difficulty,
        "visibility" => visibility
      }) do
    {width, height, count} = Map.fetch!(@difficulty, difficulty)

    slug =
      if slug in [nil, ""] do
        Base.encode16(:crypto.strong_rand_bytes(4))
      else
        slug
      end

    visibility = String.to_existing_atom(visibility)

    with {:ok, _} <-
           MineSweeper.GameServer.start_link(
             slug: slug,
             password: password,
             width: width,
             height: height,
             count: count,
             visibility: visibility
           ) do
      {:ok, slug}
    end
  end

  def get_cell!(slug, coords) do
    [{cell, _}] = Registry.lookup(GameRegistry, {:cell, slug, coords})
    cell
  end
end
