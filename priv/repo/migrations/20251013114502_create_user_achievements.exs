defmodule GreenManTavern.Repo.Migrations.CreateUserAchievements do
  use Ecto.Migration

  def change do
    create table(:user_achievements) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :achievement_id, references(:achievements, on_delete: :delete_all), null: false
      add :unlocked_at, :naive_datetime, null: false

      timestamps()
    end

    create unique_index(:user_achievements, [:user_id, :achievement_id])
    create index(:user_achievements, [:user_id])
  end
end
