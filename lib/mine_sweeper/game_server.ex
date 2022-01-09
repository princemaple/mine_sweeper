defmodule MineSweeper.GameServer do
  use GenServer, restart: :temporary

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    name = if name, do: [name: name], else: []
    GenServer.start(__MODULE__, opts, name)
  end

  def init(opts) do
    {slug, opts} = Keyword.pop(opts, :slug)

    slug =
      if slug in [nil, ""] do
        Base.encode16(:crypto.strong_rand_bytes(4))
      else
        slug
      end

    Registry.register(RealmRegistry, :public, slug)
    Registry.register(GameRegistry, slug, [])
    {:ok, %{opts: opts}}
  end
end
