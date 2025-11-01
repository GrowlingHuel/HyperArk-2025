defmodule GreenManTavernWeb.Journal.QuestLog do
  use Phoenix.Component

  attr :quests, :list, required: true
  attr :filter, :string, default: "all"

  def quest_log(assigns) do
    ~H"""
    <div class="journal-content">
      <div class="quest-header">
        <h1 class="journal-title">Quests</h1>
        <button class="parchment-button" phx-click="toggle_filter">
          Show All
        </button>
      </div>

      <div class="quest-section">
        <h3 class="quest-section-title">Active Quests</h3>
        <%= for quest <- filter_by_status(@quests, "active") do %>
          <div class="quest-entry">
            <%= quest.title %>
          </div>
        <% end %>
      </div>

      <div class="quest-section">
        <h3 class="quest-section-title">Available Quests</h3>
        <%= for quest <- filter_by_status(@quests, "available") do %>
          <div class="quest-entry">
            <%= quest.title %>
          </div>
        <% end %>
      </div>

      <div class="quest-section">
        <h3 class="quest-section-title">Completed</h3>
        <%= for quest <- filter_by_status(@quests, "completed") do %>
          <div class="quest-entry">
            <%= quest.title %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp filter_by_status(quests, status) do
    Enum.filter(quests, fn q -> q.status == status end)
  end
end
