defmodule GreenManTavernWeb.CharacterLive do
  use GreenManTavernWeb, :live_view
  require Logger

  alias GreenManTavern.Characters
  alias GreenManTavern.AI.{ClaudeClient, CharacterContext}
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

    Logger.debug("SEND MESSAGE EVENT: message=#{inspect(message)} character=#{inspect(socket.assigns.character && socket.assigns.character.name)} count=#{length(socket.assigns.chat_messages)}")

    if String.trim(message) == "" do
      Logger.debug("Message is empty, ignoring")
      {:noreply, socket}
    else
      Logger.debug("Calling send_message...")
      send_message(socket, message)
    end
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :current_message, message)}
  end

  defp send_message(socket, message) when message in [nil, ""] do
    Logger.debug("send_message: Message is nil or empty")
    {:noreply, socket}
  end

  defp send_message(socket, message) do
    user_id = socket.assigns.user_id
    character = socket.assigns.character

    Logger.debug("send_message: user_id=#{inspect(user_id)} character=#{inspect(character && character.name)} before_count=#{length(socket.assigns.chat_messages)}")

    # Add user message to UI
    user_message = %{
      id: System.unique_integer([:positive]),
      type: :user,
      content: message,
      timestamp: DateTime.utc_now()
    }

    new_messages = socket.assigns.chat_messages ++ [user_message]

    Logger.debug("Added user message, new_count=#{length(new_messages)}")

    # Update UI with user message and loading state
    socket =
      socket
      |> assign(:chat_messages, new_messages)
      |> assign(:current_message, "")
      |> assign(:is_loading, true)

    Logger.debug("Socket updated: character_set?=#{inspect(socket.assigns.character != nil)}")

    # Store user message in conversation history
    if user_id do
      try do
        Conversations.create_conversation_entry(%{
          user_id: user_id,
          character_id: character.id,
          message_type: "user",
          message_content: message
        })
        Logger.debug("Conversation entry created successfully")
      rescue
        error -> Logger.error("Error creating conversation entry: #{inspect(error)}")
      end
    end

    # Process with Claude API
    Logger.debug("Sending async process message to self")
    send(self(), {:process_with_claude, user_id, character, message})
    Logger.debug("Async message sent, returning socket")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:process_with_claude, user_id, character, message}, socket) do
    Logger.debug("Processing with Claude: user=#{inspect(user_id)} character=#{character.name} message=#{inspect(message)} count=#{length(socket.assigns.chat_messages)}")

    try do
      # Check API key
      api_key = System.get_env("ANTHROPIC_API_KEY")
      if api_key do
        Logger.debug("API key is set (length=#{String.length(api_key)})")
      else
        Logger.error("API key is NOT set")
        error_message = %{
          id: System.unique_integer([:positive]),
          type: :error,
          content: "API key not configured. Please set ANTHROPIC_API_KEY environment variable.",
          timestamp: DateTime.utc_now()
        }
        new_messages = socket.assigns.chat_messages ++ [error_message]
        {:noreply, socket |> assign(:chat_messages, new_messages) |> assign(:is_loading, false)}
      end

      # Search knowledge base for relevant context
      Logger.debug("Searching knowledge base")
      context = CharacterContext.search_knowledge_base(message, limit: 5)

      # Build character's system prompt
      Logger.debug("Building system prompt")
      system_prompt = CharacterContext.build_system_prompt(character)

      Logger.debug("Calling Claude API")

      # Query Claude API
      result = ClaudeClient.chat(message, system_prompt, context)

      Logger.debug("Claude response received: #{inspect(result, limit: 3)}")

      case result do
        {:ok, response} ->
          Logger.debug("Processing successful response. character=#{inspect(socket.assigns.character && socket.assigns.character.name)}")

          # Add character response to UI
          character_response = %{
            id: System.unique_integer([:positive]),
            type: :character,
            content: response,
            timestamp: DateTime.utc_now()
          }

          new_messages = socket.assigns.chat_messages ++ [character_response]
          Logger.debug("New messages count=#{length(new_messages)}")

          # Store character response in conversation history
          if user_id do
            try do
              Conversations.create_conversation_entry(%{
                user_id: user_id,
                character_id: character.id,
                message_type: "character",
                message_content: response
              })
              Logger.debug("Character conversation entry created")
            rescue
              error -> Logger.error("Error creating character conversation entry: #{inspect(error)}")
            end
          end

          # Update trust level based on interaction
          if user_id do
            update_trust_level(user_id, character.id, message, response)
          end

          final_socket = socket
            |> assign(:chat_messages, new_messages)
            |> assign(:is_loading, false)

          Logger.debug("Final socket character=#{inspect(final_socket.assigns.character && final_socket.assigns.character.name)} Returning socket")

          {:noreply, final_socket}

        {:error, reason} ->
          Logger.error("Error processing response: #{inspect(reason)}")

          # Show error message to user
          error_message = %{
            id: System.unique_integer([:positive]),
            type: :error,
            content: "I apologize, but I'm having trouble responding right now. Error: #{reason}",
            timestamp: DateTime.utc_now()
          }

          new_messages = socket.assigns.chat_messages ++ [error_message]

          {:noreply,
           socket
           |> assign(:chat_messages, new_messages)
           |> assign(:is_loading, false)
           |> put_flash(:error, "Failed to get response from character")}
      end
    rescue
      error ->
        Logger.error("Exception in handle_info: error=#{inspect(error)} stacktrace=#{inspect(__STACKTRACE__)}")

        # Try to recover by showing an error message
        error_message = %{
          id: System.unique_integer([:positive]),
          type: :error,
          content: "An unexpected error occurred. Please try again.",
          timestamp: DateTime.utc_now()
        }

        new_messages = (socket.assigns.chat_messages || []) ++ [error_message]

        {:noreply,
         socket
         |> assign(:chat_messages, new_messages)
         |> assign(:is_loading, false)}
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
              content: conv.message_content,
              timestamp: conv.inserted_at
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
