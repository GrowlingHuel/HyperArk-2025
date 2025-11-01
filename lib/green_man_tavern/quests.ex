defmodule GreenManTavern.Quests do
  import Ecto.Query
  alias GreenManTavern.Repo
  alias GreenManTavern.Quests.{Quest, UserQuest}

  # Quest template functions

  def list_quests(_opts \\ []) do
    Quest
    |> preload(:character)
    |> Repo.all()
  end

  def get_quest!(id), do: Repo.get!(Quest, id) |> Repo.preload(:character)

  def create_quest(attrs \\ %{}) do
    %Quest{}
    |> Quest.changeset(attrs)
    |> Repo.insert()
  end

  # User quest functions

  def list_user_quests(user_id, filter \\ "all") do
    query =
      UserQuest
      |> where([uq], uq.user_id == ^user_id)
      |> preload([uq], quest: :character)
      |> order_by([uq], desc: uq.inserted_at)

    query = case filter do
      "available" -> where(query, [uq], uq.status == "available")
      "active" -> where(query, [uq], uq.status == "active")
      "completed" -> where(query, [uq], uq.status == "completed")
      _ -> query
    end

    Repo.all(query)
  end

  def get_user_quest!(id) do
    Repo.get!(UserQuest, id) |> Repo.preload(quest: :character)
  end

  def create_user_quest(user_id, quest_id) do
    %UserQuest{}
    |> UserQuest.changeset(%{
      user_id: user_id,
      quest_id: quest_id,
      status: "available",
      progress_data: %{}
    })
    |> Repo.insert()
  end

  def accept_quest(%UserQuest{} = user_quest) do
    user_quest
    |> UserQuest.changeset(%{
      status: "active",
      started_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  def complete_quest(%UserQuest{} = user_quest) do
    user_quest
    |> UserQuest.changeset(%{
      status: "completed",
      completed_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  def search_user_quests(user_id, search_term) when is_binary(search_term) do
    search_pattern = "%#{search_term}%"

    UserQuest
    |> join(:inner, [uq], q in Quest, on: uq.quest_id == q.id)
    |> where([uq, q], uq.user_id == ^user_id)
    |> where([uq, q],
      ilike(q.title, ^search_pattern) or
      ilike(q.description, ^search_pattern)
    )
    |> preload([uq, q], quest: :character)
    |> order_by([uq], desc: uq.inserted_at)
    |> Repo.all()
  end
end
