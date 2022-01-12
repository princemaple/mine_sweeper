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
    "easy" => {10, 8, 10, 3 * 60},
    "medium" => {18, 14, 40, 10 * 60},
    "hard" => {24, 20, 99, 30 * 60},
    "extreme" => {30, 22, 145, 45 * 60}
  }

  def create_session(%{
        "slug" => slug,
        "difficulty" => difficulty,
        "visibility" => visibility
      }) do
    {width, height, count, time_limit} = Map.fetch!(@difficulty, difficulty)

    slug =
      if slug in [nil, ""] do
        Base.encode16(:crypto.strong_rand_bytes(4))
      else
        slug
      end

    visibility = String.to_existing_atom(visibility)

    game =
      DynamicSupervisor.start_child(
        GameSupervisor,
        {MineSweeper.GameServer,
         slug: slug,
         width: width,
         height: height,
         count: count,
         visibility: visibility,
         time_limit: time_limit}
      )

    with {:ok, _} <- game do
      {:ok, slug}
    end
  end
end
