defmodule GreenManTavern.Repo.Migrations.CreateUsersFixed do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :profile_data, :map, default: %{}
      add :xp, :integer, default: 0
      add :level, :integer, default: 1
      add :primary_character_id, :integer  # Will add foreign key constraint later

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    # Add unique constraint on email
    create unique_index(:users, [:email])

    # Add index on primary_character_id for foreign key performance
    create index(:users, [:primary_character_id])
  end
end