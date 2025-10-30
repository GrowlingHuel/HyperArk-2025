defmodule GreenManTavernWeb.DualPanelLive do
  use GreenManTavernWeb, :live_view

  require Logger

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
      |> assign(:characters, Characters.list_characters())

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

  # ==== Living Web: Right-panel-only events ====
  # Add node to diagram
  @impl true
  def handle_event("node_added", %{"project_id" => project_id, "x" => x, "y" => y, "temp_id" => temp_id} = _params, socket) do
    Logger.info("Node added: project=#{project_id}, x=#{x}, y=#{y}")

    # Ensure nodes assign exists
    nodes = socket.assigns[:nodes] || []

    # Fetch project
    project = Systems.get_project!(project_id)

    # Create simple node (no collision detection)
    node = %{
      id: temp_id,
      type: "default",
      position: %{x: x, y: y},
      data: %{
        label: "#{project.icon} #{project.name}",
        project_id: project_id
      }
    }

    # Update nodes
    nodes = nodes ++ [node]
    socket = assign(socket, :nodes, nodes)

    # Push to client
    socket = push_event(socket, "node_added_success", %{node: node})

    {:noreply, socket}
  end

  # Move node position
  @impl true
  def handle_event("node_moved", %{"node_id" => node_id, "position_x" => x_str, "position_y" => y_str}, socket) do
    with {:ok, x} <- parse_integer(x_str),
         {:ok, y} <- parse_integer(y_str),
         {:ok, updated_socket} <- move_node(socket, node_id, x, y) do
      {:noreply, updated_socket}
    else
      _ -> {:noreply, socket}
    end
  end

  # Add edge (basic placeholder that stores edge data)
  @impl true
  def handle_event("edge_added", %{"source_id" => source_id, "target_id" => target_id} = params, socket) do
    edge_id = Map.get(params, "edge_id") || ("edge_" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower))
    diagram = socket.assigns.diagram
    edges = socket.assigns.edges || %{}

    new_edge = %{
      "source_id" => source_id,
      "target_id" => target_id
    }

    updated_edges = Map.put(edges, edge_id, new_edge)

    updated_socket =
      case diagram do
        nil -> assign(socket, :edges, updated_edges)
        d ->
          case Diagrams.update_diagram(d, %{edges: updated_edges}) do
            {:ok, d2} -> socket |> assign(:diagram, d2) |> assign(:edges, updated_edges)
            _ -> socket
          end
      end

    {:noreply, updated_socket}
  end

  # Node selected (no-op for now; keep right panel state only)
  @impl true
  def handle_event("node_selected", _params, socket) do
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

    # Extract and persist facts before calling Claude
    if user_id && character do
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
    end

    # Process with Claude API
    Logger.debug("[DualPanel] Queuing AI processing: user_id=#{inspect(user_id)} character=#{inspect(character && character.name)} msg_len=#{String.length(message)}")
    send(self(), {:process_with_claude, user_id, character, message})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:process_with_claude, user_id, character, message}, socket) do
    Logger.debug("[DualPanel] handle_info(:process_with_claude) triggered user_id=#{inspect(user_id)} character=#{inspect(character && character.name)}")
    try do
      api_key = System.get_env("ANTHROPIC_API_KEY")
      if is_nil(api_key) or api_key == "" do
        Logger.debug("[DualPanel] Missing ANTHROPIC_API_KEY; returning error to UI")
        error_message = %{
          id: System.unique_integer([:positive]),
          type: :error,
          content: "API key not configured. Please set ANTHROPIC_API_KEY environment variable.",
          timestamp: DateTime.utc_now()
        }
        new_messages = socket.assigns.chat_messages ++ [error_message]
        {:noreply, socket |> assign(:chat_messages, new_messages) |> assign(:is_loading, false)}
      else
        # Build combined context with user facts + knowledge base
        user = if user_id, do: Accounts.get_user!(user_id), else: nil
        Logger.debug("[DualPanel] Loaded user: present?=#{!!user}")
        Logger.debug("[DualPanel] Loaded character: #{inspect(character)}")
        context = CharacterContext.build_context(user, message, limit: 5)
        Logger.debug("[DualPanel] Context built: chars=#{String.length(context || "")}\n#{String.slice(context || "", 0, 300)}...")
        system_prompt = CharacterContext.build_system_prompt(character)
        Logger.debug("[DualPanel] System prompt present?=#{system_prompt != nil and String.trim(system_prompt) != ""} len=#{String.length(system_prompt || "")}")

        # Query Claude API
        Logger.debug("[DualPanel] Calling ClaudeClient.chat... msg_len=#{String.length(message)}")
        result = ClaudeClient.chat(message, system_prompt, context)
        Logger.debug("[DualPanel] ClaudeClient result: #{inspect(result, limit: 100)}")

        case result do
          {:ok, response} ->
            Logger.debug("[DualPanel] Received AI response len=#{String.length(response)}")
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
                Logger.debug("[DualPanel] Saved AI response to conversation_history")
              rescue
                e -> Logger.error("[DualPanel] Failed to save AI response: #{inspect(e)}")
              end
            end

            # Update trust level based on interaction
            if user_id && character do
              update_trust_level(user_id, character.id, message, response)
            end

            {:noreply, socket |> assign(:chat_messages, new_messages) |> assign(:is_loading, false)}

          {:error, reason} ->
            Logger.error("[DualPanel] ClaudeClient error: #{inspect(reason)}")
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
      error ->
        Logger.error("[DualPanel] handle_info exception: #{inspect(error)}")
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

  # Collision detection temporarily disabled
  # defp find_free_position(x, y, existing_nodes, spacing \\ 80) do
  #   %{x: x, y: y}
  # end
  # defp position_occupied?(_x, _y, _nodes, _min_spacing), do: false
  # defp get_position_x(_node), do: 0
  # defp get_position_y(_node), do: 0
  # defp find_spiral_position(x, y, _nodes, _spacing, _attempt), do: %{x: x, y: y}

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

  # ==== Living Web helpers ====
  defp parse_integer(string) when is_binary(string) do
    case Integer.parse(string) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_integer}
    end
  end

  defp parse_integer(int) when is_integer(int), do: {:ok, int}
  defp parse_integer(_), do: {:error, :invalid_type}

  defp add_node(socket, project_id, x, y, temp_id) do
    projects = socket.assigns.projects || []
    project = Enum.find(projects, &(&1.id == project_id))
    diagram = socket.assigns.diagram

    node_id = "node_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)

    base_nodes = socket.assigns.nodes || %{}
    new_node_data = %{
      "project_id" => project_id,
      "x" => x,
      "y" => y,
      "instance_scale" => 1.0
    }

    raw_nodes = Map.put(base_nodes, node_id, new_node_data)
    edges = socket.assigns.edges || %{}

    # Persist if we have a diagram
    updated_socket =
      case diagram do
        nil -> socket
        d ->
          case Diagrams.update_diagram(d, %{nodes: raw_nodes}) do
            {:ok, d2} -> assign(socket, :diagram, d2)
            _ -> socket
          end
      end

    # Enrich with names
    enriched_nodes = enrich_nodes_with_project_data(raw_nodes, projects)
    updated_socket = updated_socket |> assign(:nodes, enriched_nodes) |> assign(:edges, edges)

    node_payload = %{
      temp_id: temp_id,
      id: node_id,
      project_id: project && project.id,
      name: project && project.name,
      category: project && project.category,
      inputs: project && project.inputs,
      outputs: project && project.outputs,
      position: %{x: x, y: y},
      icon_name: project && project.icon_name
    }

    {:ok, node_id, updated_socket, node_payload}
  end

  defp move_node(socket, node_id, x, y) do
    nodes = socket.assigns.nodes || %{}
    projects = socket.assigns.projects || []
    diagram = socket.assigns.diagram

    case Map.fetch(nodes, node_id) do
      :error -> {:ok, socket}
      {:ok, _node} ->
        # Update raw nodes first (preserve original structure keys)
        raw_nodes =
          nodes
          |> Enum.into(%{}, fn {id, data} ->
            {id, Map.merge(data, %{"x" => if(id == node_id, do: x, else: data["x"]), "y" => if(id == node_id, do: y, else: data["y"])})}
          end)

        # Persist
        updated_socket =
          case diagram do
            nil -> socket
            d ->
              case Diagrams.update_diagram(d, %{nodes: raw_nodes}) do
                {:ok, d2} -> assign(socket, :diagram, d2)
                _ -> socket
              end
          end

        enriched = enrich_nodes_with_project_data(raw_nodes, projects)
        {:ok, updated_socket |> assign(:nodes, enriched)}
    end
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
