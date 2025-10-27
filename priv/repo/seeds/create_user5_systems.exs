# Seed script to create user_systems for a specific user
alias GreenManTavern.Repo
alias GreenManTavern.Accounts.User
alias GreenManTavern.Systems.{System, UserSystem}

import Ecto.Query

IO.puts("\n🌱 Creating user_systems for the first user found...\n")

# List all users
all_users = Repo.all(User)
IO.puts("Found #{length(all_users)} users:")
Enum.each(all_users, fn u -> IO.puts("  • ID: #{u.id}, Email: #{u.email}") end)

# Use the last user (most likely to be the one logged in)
user = if Enum.empty?(all_users) do
  IO.puts("\n❌ No users found. Creating test user...")

  {:ok, new_user} = Repo.insert(%User{
    email: "test@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("testpassword123"),
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  })

  IO.puts("✓ Created user: #{new_user.email} (id: #{new_user.id})")
  new_user
else
  selected_user = List.last(all_users)
  IO.puts("\n✓ Using user: #{selected_user.email} (id: #{selected_user.id})")
  selected_user
end

# Get all systems
all_systems = Repo.all(System)
IO.puts("\nFound #{length(all_systems)} systems")

# Clear existing user_systems for this user
{deleted_count, _} = from(us in UserSystem, where: us.user_id == ^user.id)
|> Repo.delete_all()
IO.puts("Deleted #{deleted_count} existing user_systems\n")

# Create user_systems
positions = [
  {100, 100},
  {300, 100},
  {200, 300},
  {100, 300}
]

Enum.each(Enum.with_index(all_systems), fn {system, index} ->
  {pos_x, pos_y} = Enum.at(positions, index) || {100, 100}

  user_system_attrs = %{
    user_id: user.id,
    system_id: system.id,
    status: "active",
    position_x: pos_x,
    position_y: pos_y,
    custom_notes: "Living Web test system"
  }

  changeset = UserSystem.changeset(%UserSystem{}, user_system_attrs)

  case Repo.insert(changeset) do
    {:ok, _} -> IO.puts("  ✓ Created: #{system.name} at (#{pos_x}, #{pos_y})")
    {:error, changeset} -> IO.puts("  ✗ Failed: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\n🎉 Done!\n")
