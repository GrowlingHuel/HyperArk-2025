defmodule GreenManTavernWeb.DatabaseLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    {:ok,
     socket
     |> assign(:page_title, "Database")
     |> assign(:facts, get_facts(current_user))}
  end

  @impl true
  def handle_event("add_fact", %{"fact" => fact_params}, socket) do
    user = socket.assigns.current_user
    facts = get_facts(user)
    new_fact = build_fact_from_params(fact_params)
    updated = [new_fact | facts]
    persist_facts(user, updated)
    {:noreply, assign(socket, :facts, updated)}
  end

  def handle_event("update_fact", %{"index" => idx_str, "field" => field, "value" => value}, socket) do
    user = socket.assigns.current_user
    idx = String.to_integer(idx_str)
    facts = get_facts(user)
    updated =
      facts
      |> Enum.with_index()
      |> Enum.map(fn {f, i} -> if i == idx, do: Map.put(f, field, value), else: f end)

    persist_facts(user, updated)
    {:noreply, assign(socket, :facts, updated)}
  end

  def handle_event("delete_fact", %{"index" => idx_str}, socket) do
    user = socket.assigns.current_user
    idx = String.to_integer(idx_str)
    facts = get_facts(user)
    updated = facts |> Enum.with_index() |> Enum.reject(fn {_f, i} -> i == idx end) |> Enum.map(&elem(&1, 0))
    persist_facts(user, updated)
    {:noreply, assign(socket, :facts, updated)}
  end

  defp get_facts(user) do
    (user.profile_data || %{})["facts"] || []
  end

  defp persist_facts(user, facts) do
    pd = Map.put(user.profile_data || %{}, "facts", facts)
    _ = Accounts.update_user(user, %{profile_data: pd})
  end

  defp build_fact_from_params(params) do
    %{
      "type" => Map.get(params, "type", "unknown"),
      "key" => Map.get(params, "key", "unknown"),
      "value" => Map.get(params, "value", ""),
      "confidence" => Map.get(params, "confidence", "0.5"),
      "source" => Map.get(params, "source", "manual"),
      "learned_at" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      "context" => Map.get(params, "context")
    }
  end
end
