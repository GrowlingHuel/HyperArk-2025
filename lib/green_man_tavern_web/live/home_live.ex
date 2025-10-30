defmodule GreenManTavernWeb.HomeLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Characters
  alias GreenManTavern.AI.{ClaudeClient, CharacterContext}
  alias GreenManTavern.Conversations

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
      |> assign(:is_loading, false)
      |> assign(:characters, Characters.list_characters())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Handle character parameter from URL
    character =
      case params["character"] do
        nil ->
          nil

        character_id ->
          try do
            Characters.get_character!(String.to_integer(character_id))
          rescue
            _ -> nil
          end
      end

    socket =
      if character do
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

    socket =
      socket
      |> assign(:character, character)
      |> assign(:left_window_title, "Tavern - #{character.name}")
      |> assign(:chat_messages, [])
      |> assign(:current_message, "")

    IO.inspect(socket.assigns.character, label: "HOME LIVE - SOCKET ASSIGNS AFTER SELECTION")
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    character = socket.assigns[:character]
    user_id = socket.assigns[:user_id]

    IO.puts("=== SEND MESSAGE EVENT ===")
    IO.puts("Message: #{message}")
    IO.puts("Character: #{inspect(character && character.name)}")

    if character && String.trim(message) != "" do
      # Add user message
      user_message = %{
        id: System.unique_integer([:positive]),
        type: :user,
        content: message,
        timestamp: DateTime.utc_now()
      }

      new_messages = (socket.assigns[:chat_messages] || []) ++ [user_message]

      # Store in conversation history
      if user_id do
        Conversations.create_conversation_entry(%{
          user_id: user_id,
          character_id: character.id,
          message_type: "user",
          message_content: message
        })
      end

      # Extract and persist facts asynchronously
      Task.start(fn ->
        alias GreenManTavern.AI.FactExtractor
        alias GreenManTavern.Accounts

        facts = FactExtractor.extract_facts(message, character.name)
        if length(facts) > 0 do
          user = Accounts.get_user!(user_id)
          existing = (user.profile_data || %{})["facts"] || []
          merged = FactExtractor.merge_facts(existing, facts)
          new_pd = Map.put(user.profile_data || %{}, "facts", merged)
          _ = Accounts.update_user(user, %{profile_data: new_pd})
        end
      end)

      socket =
        socket
        |> assign(:chat_messages, new_messages)
        |> assign(:current_message, "")
        |> assign(:is_loading, true)
        |> push_event("new-message", %{
          message: %{
            id: user_message.id,
            type: "user",
            content: message,
            timestamp: DateTime.to_iso8601(user_message.timestamp)
          }
        })

      # Process with Claude
      IO.puts("=== SENDING TO HANDLE_INFO ===")
      send(self(), {:process_with_claude, user_id, character, message})

      {:noreply, socket}
    else
      IO.puts("=== MESSAGE REJECTED: No character or empty message ===")
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :current_message, message)}
  end

  @impl true
  def handle_info({:process_with_claude, user_id, character, message}, socket) do
    IO.puts("=== HANDLE_INFO CALLED IN HOMELIVE ===")
    IO.puts("User: #{user_id}, Character: #{character.name}, Message: #{message}")

    # CRITICAL: Verify character exists on socket
    IO.puts("=== CHECKING SOCKET CHARACTER ===")
    IO.puts("Socket character: #{inspect(socket.assigns.character)}")

    # Build combined context with user facts + knowledge base
    IO.puts("=== BUILDING CONTEXT WITH FACTS ===")
    user = if user_id, do: Accounts.get_user!(user_id), else: nil
    context = CharacterContext.build_context(user, message, limit: 5)
    IO.puts("=== CONTEXT RETRIEVED ===")
    IO.puts(context)

    # Build system prompt
    system_prompt = CharacterContext.build_system_prompt(character)
    IO.puts("=== CALLING CLAUDE API ===")

    # Call Claude
    result = ClaudeClient.chat(message, system_prompt, context)
    IO.puts("=== CLAUDE RESULT: #{inspect(result)} ===")

    case result do
      {:ok, response} ->
        IO.puts("=== SUCCESS! Got response ===")
        IO.puts("Current messages count: #{length(socket.assigns.chat_messages)}")
        IO.puts("Current socket character: #{inspect(socket.assigns.character)}")

        character_response = %{
          id: System.unique_integer([:positive]),
          type: :character,
          content: response,
          timestamp: DateTime.utc_now()
        }

        new_messages = socket.assigns.chat_messages ++ [character_response]
        IO.puts("New messages count: #{length(new_messages)}")

        # Store in conversation history
        if user_id do
          Conversations.create_conversation_entry(%{
            user_id: user_id,
            character_id: character.id,
            message_type: "character",
            message_content: response
          })
        end

        new_socket =
          socket
          |> assign(:chat_messages, new_messages)
          |> assign(:is_loading, false)
          |> push_event("new-message", %{
            message: %{
              id: character_response.id,
              type: "character",
              content: response,
              character_name: character.name,
              timestamp: DateTime.to_iso8601(character_response.timestamp)
            }
          })

        IO.puts("New socket character: #{inspect(new_socket.assigns.character)}")
        IO.puts("=== RETURNING SOCKET ===")

        {:noreply, new_socket}

      {:error, reason} ->
        IO.puts("=== ERROR: #{inspect(reason)} ===")

        error_message = %{
          id: System.unique_integer([:positive]),
          type: :error,
          content: "Sorry, I had trouble responding. Error: #{inspect(reason)}",
          timestamp: DateTime.utc_now()
        }

        new_messages = socket.assigns.chat_messages ++ [error_message]

        {:noreply,
         socket
         |> assign(:chat_messages, new_messages)
         |> assign(:is_loading, false)}
    end
  end
end
