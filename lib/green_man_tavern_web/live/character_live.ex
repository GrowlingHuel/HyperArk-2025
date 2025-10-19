defmodule GreenManTavernWeb.CharacterLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Characters

  @impl true
  def mount(%{"character_name" => character_name}, _session, socket) do
    case Characters.get_character_by_slug(character_name) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Character not found")
         |> push_navigate(to: ~p"/")}

      character ->
        socket =
          socket
          |> assign(:character, character)
          |> assign(:page_title, character.name)
          |> assign(:left_window_title, "Tavern - #{character.name}")
          |> assign(:right_window_title, "Interaction Results")
          |> assign(:chat_messages, [])
          |> assign(:current_message, "")

        {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"character_name" => character_name}, _url, socket) do
    case Characters.get_character_by_slug(character_name) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Character not found")
         |> push_navigate(to: ~p"/")}

      character ->
        socket =
          socket
          |> assign(:character, character)
          |> assign(:page_title, character.name)
          |> assign(:left_window_title, "Tavern - #{character.name}")
          |> assign(:right_window_title, "Interaction Results")
          |> assign(:chat_messages, [])
          |> assign(:current_message, "")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("back_to_tavern", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  @impl true
  def handle_event("send_message", %{"key" => "Enter", "value" => message}, socket) do
    send_message(socket, message)
  end

  @impl true
  def handle_event("send_message", _params, socket) do
    # Handle button click - get message from input field
    message = socket.assigns.current_message
    send_message(socket, message)
  end

  @impl true
  def handle_event("update_message", %{"value" => message}, socket) do
    {:noreply, assign(socket, :current_message, message)}
  end

  defp send_message(socket, message) when message in [nil, ""] do
    {:noreply, socket}
  end

  defp send_message(socket, message) do
    # Add user message
    user_message = %{
      id: System.unique_integer([:positive]),
      type: :user,
      content: message,
      timestamp: DateTime.utc_now()
    }

    # Add character response (placeholder for now)
    character_response = %{
      id: System.unique_integer([:positive]),
      type: :character,
      content: "Thank you for your message: '#{message}'. I'm still learning how to respond meaningfully.",
      timestamp: DateTime.utc_now()
    }

    new_messages = socket.assigns.chat_messages ++ [user_message, character_response]

    {:noreply,
     socket
     |> assign(:chat_messages, new_messages)
     |> assign(:current_message, "")}
  end

end
