defmodule GreenManTavernWeb.CharacterLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Characters
  alias GreenManTavern.MindsDB.{MemoryExtractor, ContextBuilder, Client}
  alias GreenManTavern.Conversations
  alias GreenManTavern.Accounts

  @impl true
  def mount(%{"character_name" => character_name}, _session, socket) do
    # User is guaranteed to be authenticated due to router pipeline
    current_user = socket.assigns.current_user
    character = Characters.get_character_by_slug(character_name)

    case character do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Character not found")
         |> push_navigate(to: ~p"/")}

      character ->
        socket =
          socket
          |> assign(:character, character)
          |> assign(:user_id, current_user.id)
          |> assign(:page_title, character.name)
          |> assign(:left_window_title, "Tavern - #{character.name}")
          |> assign(:right_window_title, "Interaction Results")
          |> assign(:chat_messages, [])
          |> assign(:current_message, "")
          |> assign(:is_loading, false)
          |> load_conversation_history(current_user.id, character.id)

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

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("back_to_tavern", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
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
      MemoryExtractor.extract_and_store_projects(user_id, message)
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
      Conversations.create_conversation_entry(%{
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
    context = ContextBuilder.build_user_context(user_id, character)

    # Debug logging before MindsDB call
    IO.puts("=== CALLING MINDSDB ===")
    IO.puts("Agent: #{character.mindsdb_agent_name}")

    # Query MindsDB for character response
    result = Client.query_agent(character.mindsdb_agent_name, message, context)

    # Debug logging after MindsDB call
    IO.puts("=== MINDSDB RESPONSE ===")
    IO.puts("Result: #{inspect(result)}")

    case result do
      {:ok, response} ->
        # Add character response to UI
        character_response = %{
          id: System.unique_integer([:positive]),
          type: :character,
          content: response,
          timestamp: DateTime.utc_now()
        }

        new_messages = socket.assigns.chat_messages ++ [character_response]

        # Store character response in conversation history
        Conversations.create_conversation_entry(%{
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

      {:error, reason} ->
        # Handle MindsDB error
        error_response = %{
          id: System.unique_integer([:positive]),
          type: :character,
          content: "I'm having trouble processing that right now. Please try again later.",
          timestamp: DateTime.utc_now()
        }

        new_messages = socket.assigns.chat_messages ++ [error_response]

        {:noreply,
         socket
         |> assign(:chat_messages, new_messages)
         |> assign(:is_loading, false)
         |> put_flash(:error, "Error: #{reason}")}
    end
  end

  defp load_conversation_history(socket, user_id, _character_id) when is_nil(user_id) do
    socket
  end

  defp load_conversation_history(socket, user_id, character_id) do
    case Conversations.get_recent_conversation(user_id, character_id, 10) do
      nil ->
        socket

      conversations ->
        messages =
          conversations
          |> Enum.map(fn conv ->
            %{
              id: conv.id,
              type: String.to_atom(conv.message_type),
              content: conv.content,
              timestamp: conv.timestamp
            }
          end)

        assign(socket, :chat_messages, messages)
    end
  end


  defp update_trust_level(user_id, character_id, user_message, character_response) do
    # Simple trust calculation based on message length and response quality
    trust_delta = calculate_trust_delta(user_message, character_response)

    # Update user's trust level with this character
    Accounts.update_user_character_trust(user_id, character_id, trust_delta)
  end

  defp calculate_trust_delta(user_message, character_response) do
    # Basic trust calculation - can be enhanced with more sophisticated logic
    message_length = String.length(user_message)
    response_length = String.length(character_response)

    cond do
      message_length > 50 and response_length > 100 -> 0.1
      message_length > 20 and response_length > 50 -> 0.05
      true -> 0.01
    end
  end
end
