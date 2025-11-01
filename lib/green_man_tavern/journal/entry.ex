defmodule GreenManTavern.Journal.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "journal_entries" do
    field :entry_date, :string
    field :day_number, :integer
    field :title, :string
    field :body, :string
    field :source_type, :string
    field :source_id, :integer

    belongs_to :user, GreenManTavern.Accounts.User

    timestamps()
  end

  @source_types ["character_conversation", "quest_completion", "system_action", "manual_entry"]

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:user_id, :entry_date, :day_number, :title, :body, :source_type, :source_id])
    |> validate_required([:user_id, :entry_date, :day_number, :body, :source_type])
    |> validate_inclusion(:source_type, @source_types)
    |> validate_number(:day_number, greater_than: 0)
    |> foreign_key_constraint(:user_id)
  end
end
