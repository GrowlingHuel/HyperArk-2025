defmodule GreenManTavern.Repo.Migrations.AddColorSchemeToSystems do
  use Ecto.Migration

  def change do
    alter table(:systems) do
      add :color_scheme, :string
    end
  end
end
