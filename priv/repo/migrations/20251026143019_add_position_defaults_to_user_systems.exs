defmodule GreenManTavern.Repo.Migrations.AddPositionDefaultsToUserSystems do
  use Ecto.Migration

  def up do
    # Set defaults for existing NULL values
    execute "UPDATE user_systems SET position_x = 0 WHERE position_x IS NULL"
    execute "UPDATE user_systems SET position_y = 0 WHERE position_y IS NULL"

    # Add non-null constraints and defaults
    alter table(:user_systems) do
      modify :position_x, :integer, default: 0, null: false
      modify :position_y, :integer, default: 0, null: false
    end
  end

  def down do
    # Remove constraints
    alter table(:user_systems) do
      modify :position_x, :integer, default: nil, null: true
      modify :position_y, :integer, default: nil, null: true
    end
  end
end
