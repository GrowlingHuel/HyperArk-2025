defmodule GreenManTavernWeb.PageController do
  use GreenManTavernWeb, :controller

  alias GreenManTavern.Repo
  alias GreenManTavern.Characters.Character

  def home(conn, _params) do
    characters = Repo.all(Character) |> Repo.preload([])
    render(conn, :home, characters: characters, layout: false)
  end
end
