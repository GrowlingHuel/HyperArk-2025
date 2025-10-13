defmodule GreenManTavernWeb.PageController do
  use GreenManTavernWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
