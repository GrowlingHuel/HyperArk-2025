defmodule GreenManTavern.Repo.Migrations.AddSystemPromptToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :system_prompt, :text
    end
  end
end
