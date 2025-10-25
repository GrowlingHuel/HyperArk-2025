defmodule GreenManTavernWeb.HomeLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Characters

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(:user_id, current_user.id)
      |> assign(:page_title, "Green Man Tavern")
      |> assign(:left_window_title, "Green Man Tavern")
      |> assign(:right_window_title, "Welcome")
      |> assign(:character, nil)
      |> assign(:chat_messages, [])
      |> assign(:current_message, "")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Handle character parameter from URL
    character = case params["character"] do
      nil -> nil
      character_id ->
        try do
          Characters.get_character!(String.to_integer(character_id))
        rescue
          _ -> nil
        end
    end

    socket = if character do
      socket
      |> assign(:character, character)
      |> assign(:left_window_title, "Tavern - #{character.name}")
    else
      socket
      |> assign(:character, nil)
      |> assign(:left_window_title, "Green Man Tavern")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    IO.inspect(character_id, label: "HOME LIVE - CHARACTER SELECTION - ID")

    character = Characters.get_character!(character_id)
    IO.inspect(character.name, label: "HOME LIVE - CHARACTER SELECTION - NAME")

    socket = socket
      |> assign(:character, character)
      |> assign(:left_window_title, "Tavern - #{character.name}")
      |> assign(:chat_messages, [])
      |> assign(:current_message, "")

    IO.inspect(socket.assigns.character, label: "HOME LIVE - SOCKET ASSIGNS AFTER SELECTION")
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{}, socket) do
    message = socket.assigns.current_message || ""

    if String.trim(message) == "" do
      {:noreply, socket}
    else
      IO.puts("=== SEND MESSAGE TRIGGERED (Button) ===")
      IO.puts("Sending async message: #{message}")
      send_message(socket, message)
    end
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :current_message, message)}
  end

  defp send_message(socket, message) when message in [nil, ""] do
    {:noreply, socket}
  end

  defp send_message(socket, message) do
    user_id = socket.assigns.user_id
    character = socket.assigns.character

    # Extract and store projects from user message
    if user_id do
      GreenManTavern.MindsDB.MemoryExtractor.extract_and_store_projects(user_id, message)
    end

    # Add user message to UI
    user_message = %{
      id: System.unique_integer([:positive]),
      type: :user,
      content: message,
      timestamp: DateTime.utc_now()
    }

    new_messages = socket.assigns.chat_messages ++ [user_message]

    # Update UI with user message and loading state
    socket =
      socket
      |> assign(:chat_messages, new_messages)
      |> assign(:current_message, "")
      |> assign(:is_loading, true)

    # Store user message in conversation history
    if user_id do
      GreenManTavern.Conversations.create_conversation_entry(%{
        user_id: user_id,
        character_id: character.id,
        message_type: "user",
        content: message,
        timestamp: DateTime.utc_now()
      })
    end

    # Send to MindsDB for processing
    if user_id do
      IO.puts("🎯 [1/4] SENDING ASYNC MESSAGE TO SELF: '#{message}'")
      IO.puts("🎯 [2/4] Self PID: #{inspect(self())}")
      send(self(), {:process_with_mindsdb, user_id, character, message})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:process_with_mindsdb, user_id, character, message}, socket) do
    # Debug logging - handle_info called
    IO.puts("🎯 [3/4] RECEIVED ASYNC MESSAGE: '#{message}'")
    IO.puts("🎯 [4/4] Processing started for: '#{message}'")
    IO.puts("=== HANDLE INFO CALLED ===")
    IO.puts("Processing message: #{message}")

    # Debug logging
    IO.puts("=== PROCESSING MESSAGE ===")
    IO.puts("User: #{user_id}, Character: #{character.name}")
    IO.puts("Message: #{message}")

    # Build context for MindsDB query
    context = GreenManTavern.MindsDB.ContextBuilder.build_character_context(user_id, character.id)

    # Debug logging before MindsDB call
    IO.puts("=== CALLING MINDSDB ===")
    IO.puts("Agent: #{character.mindsdb_agent_name}")

    # Query MindsDB for character response
    result = GreenManTavern.MindsDB.Client.query_agent(character.mindsdb_agent_name, message, context)

    # Debug logging after MindsDB call
    IO.puts("=== MINDSDB RESPONSE ===")
    IO.puts("Result: #{inspect(result)}")

    case result do
      {:ok, response} ->

        character_response = %{
          id: System.unique_integer([:positive]),
          type: :character,
          content: response,
          timestamp: DateTime.utc_now()
        }

        new_messages = socket.assigns.chat_messages ++ [character_response]

        # Store character response in conversation history
        GreenManTavern.Conversations.create_conversation_entry(%{
          user_id: user_id,
          character_id: character.id,
          message_type: "character",
          content: response,
          timestamp: DateTime.utc_now()
        })

        # Update trust level based on interaction
        update_trust_level(user_id, character.id, message, response)

        {:noreply,
         socket
         |> assign(:chat_messages, new_messages)
         |> assign(:is_loading, false)}
    end
  end

  defp update_trust_level(_user_id, _character_id, _message, _response) do
    # TODO: Implement trust level updates
    :ok
  end
end
