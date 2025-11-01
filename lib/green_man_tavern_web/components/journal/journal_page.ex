defmodule GreenManTavernWeb.Journal.JournalPage do
  use Phoenix.Component

  attr :entries, :list, required: true
  attr :search_term, :string, default: ""

  def journal_page(assigns) do
    ~H"""
    <div class="journal-content">
      <h1 class="journal-title">Journal</h1>

      <%= for entry <- @entries do %>
        <div class="journal-entry">
          <div class="journal-date">
            <%= entry.entry_date %> (Day <%= entry.day_number %>)
          </div>
          <div class="journal-text">
            <%= entry.body %>
          </div>
        </div>
      <% end %>

      <div class="journal-search">
        <input
          type="text"
          placeholder="Search journal entries..."
          phx-change="search_journal"
          phx-debounce="300"
          value={@search_term}
          name="search"
          class="parchment-input"
        />
      </div>
    </div>
    """
  end
end
