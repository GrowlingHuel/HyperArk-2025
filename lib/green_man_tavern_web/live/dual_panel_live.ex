defmodule GreenManTavernWeb.DualPanelLive do
  use GreenManTavernWeb, :live_view

  alias Phoenix.PubSub
  alias GreenManTavern.Characters
  alias GreenManTavern.{Systems, Diagrams, Conversations, Accounts}
  alias GreenManTavern.AI.{ClaudeClient, CharacterContext}

  @pubsub GreenManTavern.PubSub
  @topic "navigation"

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket) do
      PubSub.subscribe(@pubsub, @topic)
    end

    socket =
      socket
      |> assign(:user_id, current_user && current_user.id)
      |> assign(:left_panel_view, :tavern_home)
      |> assign(:selected_character, nil)
      |> assign(:right_panel_action, :home)
      |> assign(:chat_messages, [])
      |> assign(:current_message, "")
      |> assign(:is_loading, false)

    # Load Living Web data if user is authenticated
    projects = Systems.list_projects()

    diagram =
      if current_user do
        case Diagrams.get_or_create_diagram(current_user.id) do
          {:ok, d} -> d
          _ -> nil
        end
      else
        nil
      end

    raw_nodes = if diagram && is_map(diagram.nodes), do: diagram.nodes, else: %{}
    edges = if diagram && is_map(diagram.edges), do: diagram.edges, else: %{}
    nodes = enrich_nodes_with_project_data(raw_nodes, projects)

    socket =
      socket
      |> assign(:projects, projects)
      |> assign(:diagram, diagram)
      |> assign(:nodes, nodes)
      |> assign(:edges, edges)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    # Set right panel action from live_action
    action = socket.assigns.live_action || :home

    socket =
      socket
      |> assign(:right_panel_action, action)
      |> assign(:page_title, page_title(action))

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_character", %{"character_slug" => slug}, socket) do
    case Characters.get_character_by_slug(slug) do
      nil ->
        {:noreply, socket}

      character ->
        socket =
          socket
          |> assign(:selected_character, character)
          |> assign(:left_panel_view, :character_chat)
          |> assign(:chat_messages, [])

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("show_tavern_home", _params, socket) do
    socket =
      socket
      |> assign(:left_panel_view, :tavern_home)
      |> assign(:selected_character, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("navigate_right", %{"action" => action}, socket) do
    action_atom = String.to_existing_atom(action)

    socket =
      socket
      |> assign(:right_panel_action, action_atom)

    {:noreply, socket}
  end

  # Chat event handlers
  @impl true
  def handle_event("send_message", %{}, socket) do
    message = socket.assigns.current_message || ""

    if String.trim(message) == "" do
      {:noreply, socket}
    else
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
    character = socket.assigns.selected_character

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
    if user_id && character do
      try do
        Conversations.create_conversation_entry(%{
          user_id: user_id,
          character_id: character.id,
          message_type: "user",
          message_content: message
        })
      rescue
        _ -> :ok
      end
    end

    # Process with Claude API
    send(self(), {:process_with_claude, user_id, character, message})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:process_with_claude, user_id, character, message}, socket) do
    try do
      api_key = System.get_env("ANTHROPIC_API_KEY")
      if is_nil(api_key) or api_key == "" do
        error_message = %{
          id: System.unique_integer([:positive]),
          type: :error,
          content: "API key not configured. Please set ANTHROPIC_API_KEY environment variable.",
          timestamp: DateTime.utc_now()
        }
        new_messages = socket.assigns.chat_messages ++ [error_message]
        {:noreply, socket |> assign(:chat_messages, new_messages) |> assign(:is_loading, false)}
      else
        # Search knowledge base for relevant context
        context = CharacterContext.search_knowledge_base(message, limit: 5)
        system_prompt = CharacterContext.build_system_prompt(character)

        # Query Claude API
        result = ClaudeClient.chat(message, system_prompt, context)

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
            if user_id && character do
              try do
                Conversations.create_conversation_entry(%{
                  user_id: user_id,
                  character_id: character.id,
                  message_type: "character",
                  message_content: response
                })
              rescue
                _ -> :ok
              end
            end

            # Update trust level based on interaction
            if user_id && character do
              update_trust_level(user_id, character.id, message, response)
            end

            {:noreply, socket |> assign(:chat_messages, new_messages) |> assign(:is_loading, false)}

          {:error, reason} ->
            error_message = %{
              id: System.unique_integer([:positive]),
              type: :error,
              content: "I apologize, but I'm having trouble responding right now. Error: #{inspect(reason)}",
              timestamp: DateTime.utc_now()
            }

            new_messages = socket.assigns.chat_messages ++ [error_message]

            {:noreply,
             socket
             |> assign(:chat_messages, new_messages)
             |> assign(:is_loading, false)
             |> put_flash(:error, "Failed to get response from character")}
        end
      end
    rescue
      _error ->
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

  defp page_title(:home), do: "Green Man Tavern"
  defp page_title(:living_web), do: "Living Web"
  defp page_title(_), do: "Green Man Tavern"

  defp enrich_nodes_with_project_data(raw_nodes, projects) do
    project_map = Map.new(projects, fn p -> {p.id, p} end)

    Enum.reduce(raw_nodes, %{}, fn {node_id, node_data}, acc ->
      project_id = node_data["project_id"]
      case Map.get(project_map, project_id) do
        nil ->
          enriched = Map.merge(node_data, %{"name" => "Unknown Project", "category" => "unknown"})
          Map.put(acc, node_id, enriched)
        project ->
          enriched = Map.merge(node_data, %{"name" => project.name, "category" => project.category})
          Map.put(acc, node_id, enriched)
      end
    end)
  end

  defp update_trust_level(user_id, character_id, user_message, character_response) do
    # Simple trust calculation based on message length and response quality
    trust_delta = calculate_trust_delta(user_message, character_response)

    # Update user's trust level with this character
    Accounts.update_user_character_trust(user_id, character_id, trust_delta)
  end

  defp calculate_trust_delta(user_message, character_response) do
    message_length = String.length(user_message)
    response_length = String.length(character_response)

    cond do
      message_length > 50 and response_length > 100 -> 0.1
      message_length > 20 and response_length > 50 -> 0.05
      true -> 0.01
    end
  end
end
