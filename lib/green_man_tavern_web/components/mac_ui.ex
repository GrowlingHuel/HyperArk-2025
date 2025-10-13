defmodule GreenManTavernWeb.Components.MacUI do
  @moduledoc """
  Main entry module for MacUI components.
  Provides short names like <MacUI.button> and <MacUI.window>.
  """

  use Phoenix.Component

  alias GreenManTavernWeb.Components.MacUI.{
    Window,
    Button,
    Card,
    TextField,
    Checkbox,
    WindowChrome
  }

  # Re-expose function components
  defdelegate window(assigns), to: Window
  defdelegate button(assigns), to: Button
  defdelegate card(assigns), to: Card
  defdelegate text_field(assigns), to: TextField
  defdelegate checkbox(assigns), to: Checkbox
  defdelegate window_chrome(assigns), to: WindowChrome
end
