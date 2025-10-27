defmodule GreenManTavern.Repo.Migrations.AddTimestampsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end
  end
end
