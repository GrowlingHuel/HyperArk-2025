# Seed script to create user_id 5 to match the session
alias GreenManTavern.Repo
alias GreenManTavern.Accounts.User
alias GreenManTavern.Systems.{System, UserSystem}

import Ecto.Query

IO.puts("\n🔧 Creating user_id 5 to match session...\n")

# Get or create user 5
user = case Repo.get(User, 5) do
  nil ->
    IO.puts("User 5 doesn't exist. Creating...")

    # First ensure users 3 and 4 exist
    if !Repo.get(User, 3) do
      case Repo.insert(%User{
        email: "user3@hyperark.example",
        hashed_password: Bcrypt.hash_pwd_salt("password123"),
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }) do
        {:ok, _} -> IO.puts("  Created user 3")
        {:error, _} -> IO.puts("  User 3 already exists")
      end
    end

    if !Repo.get(User, 4) do
      case Repo.insert(%User{
        email: "user4@hyperark.example",
        hashed_password: Bcrypt.hash_pwd_salt("password123"),
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }) do
        {:ok, _} -> IO.puts("  Created user 4")
        {:error, _} -> IO.puts("  User 4 already exists")
      end
    end

    # Create user 5
    case Repo.insert(%User{
      email: "main@hyperark.example",
      hashed_password: Bcrypt.hash_pwd_salt("password123"),
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }) do
      {:ok, new_user} ->
        IO.puts("  ✓ Created user 5: #{new_user.email}")
        new_user
      {:error, changeset} ->
        IO.puts("  ✗ Failed to create user 5: #{inspect(changeset.errors)}")
        # Get the last user as fallback
        List.last(Repo.all(User))
    end

  existing_user ->
    IO.puts("✓ User 5 already exists: #{existing_user.email}")
    existing_user
end

# Now create user_systems for user 5
IO.puts("\nCreating user_systems for user 5...")

all_systems = Repo.all(System)
IO.puts("Found #{length(all_systems)} systems")

# Clear existing user_systems for this user
{deleted_count, _} = from(us in UserSystem, where: us.user_id == ^user.id)
|> Repo.delete_all()
IO.puts("Deleted #{deleted_count} existing user_systems\n")

# Create user_systems
positions = [
  {150, 150},
  {350, 150},
  {250, 350},
  {150, 350}
]

Enum.each(Enum.with_index(all_systems), fn {system, index} ->
  {pos_x, pos_y} = Enum.at(positions, index) || {100, 100}

  user_system_attrs = %{
    user_id: user.id,
    system_id: system.id,
    status: "active",
    position_x: pos_x,
    position_y: pos_y,
    custom_notes: "Living Web system for user 5"
  }

  changeset = UserSystem.changeset(%UserSystem{}, user_system_attrs)

  case Repo.insert(changeset) do
    {:ok, _} -> IO.puts("  ✓ Created: #{system.name} at (#{pos_x}, #{pos_y})")
    {:error, changeset} -> IO.puts("  ✗ Failed: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\n🎉 Done! User 5 now has user_systems!\n")
