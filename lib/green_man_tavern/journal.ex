defmodule GreenManTavern.Journal do
  import Ecto.Query
  alias GreenManTavern.Repo
  alias GreenManTavern.Journal.Entry

  def list_entries(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Entry
    |> where([e], e.user_id == ^user_id)
    |> order_by([e], desc: e.day_number, desc: e.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_entry!(id), do: Repo.get!(Entry, id)

  def create_entry(attrs \\ %{}) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  def update_entry(%Entry{} = entry, attrs) do
    entry
    |> Entry.changeset(attrs)
    |> Repo.update()
  end

  def delete_entry(%Entry{} = entry) do
    Repo.delete(entry)
  end

  def search_entries(user_id, search_term) when is_binary(search_term) do
    search_pattern = "%#{search_term}%"

    Entry
    |> where([e], e.user_id == ^user_id)
    |> where([e],
      ilike(e.title, ^search_pattern) or
      ilike(e.body, ^search_pattern) or
      ilike(e.entry_date, ^search_pattern)
    )
    |> order_by([e], desc: e.day_number, desc: e.inserted_at)
    |> Repo.all()
  end
end
