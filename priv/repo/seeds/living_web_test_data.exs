# Seed script for Living Web test data
alias GreenManTavern.Repo
alias GreenManTavern.Accounts.User
alias GreenManTavern.Systems.{System, UserSystem}

import Ecto.Query

IO.puts("\n🌱 Seeding Living Web test data...\n")

# Check if systems exist
existing_systems = Repo.all(System)

if Enum.empty?(existing_systems) do
  IO.puts("Creating sample systems...")

  # Create sample systems
  systems = [
    %{
      name: "Compost Bin",
      category: "waste",
      system_type: "process",
      description: "Biodegradable waste decomposition for soil enrichment",
      requirements: "Organic materials, water, aeration",
      default_inputs: ["Food scraps", "Yard waste", "Water"],
      default_outputs: ["Compost", "Nutrients"],
      skill_level: "beginner",
      color_scheme: "grey"
    },
    %{
      name: "Rainwater Collection",
      category: "water",
      system_type: "storage",
      description: "Captures and stores rainwater for irrigation",
      requirements: "Rainfall, collection surface, storage container",
      default_inputs: ["Rainfall"],
      default_outputs: ["Stored water"],
      skill_level: "intermediate",
      color_scheme: "grey"
    },
    %{
      name: "Herb Garden",
      category: "food",
      system_type: "resource",
      description: "Small-scale herb cultivation for culinary use",
      requirements: "Sunlight, soil, water, seeds",
      default_inputs: ["Water", "Compost", "Seeds"],
      default_outputs: ["Herbs", "Cuttings"],
      skill_level: "beginner",
      color_scheme: "grey"
    },
    %{
      name: "Solar Panel",
      category: "energy",
      system_type: "storage",
      description: "Converts sunlight to electrical energy",
      requirements: "Sunlight, panel installation",
      default_inputs: ["Sunlight"],
      default_outputs: ["Electricity"],
      skill_level: "advanced",
      color_scheme: "grey"
    }
  ]

  Enum.each(systems, fn system_attrs ->
    changeset = System.changeset(%System{}, system_attrs)
    case Repo.insert(changeset) do
      {:ok, system} -> IO.puts("  ✓ Created: #{system.name}")
      {:error, changeset} -> IO.puts("  ✗ Failed: #{inspect(changeset.errors)}")
    end
  end)
else
  IO.puts("Found #{length(existing_systems)} existing systems")
  Enum.each(existing_systems, fn s -> IO.puts("  • #{s.name} (#{s.system_type})") end)
end

# Get all systems for user_systems
all_systems = Repo.all(System)

# List all users
IO.puts("\nChecking users...")
all_users = Repo.all(User)
IO.puts("  Found #{length(all_users)} users:")
Enum.each(all_users, fn u -> IO.puts("    • ID: #{u.id}, Email: #{u.email}") end)

# Use first user or create one
user_id = if Enum.empty?(all_users) do
  IO.puts("\n❌ No users found. Creating test user...")

  # Create a test user
  {:ok, test_user} = Repo.insert(%User{
    email: "test@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("testpassword123"),
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  })

  IO.puts("✓ Created test user: #{test_user.email} (id: #{test_user.id})")
  test_user.id
else
  # Use the first user found
  first_user = List.first(all_users)
  IO.puts("\n✓ Using existing user: #{first_user.email} (id: #{first_user.id})")
  first_user.id
end
# Clear existing user_systems for this user
IO.puts("\nClearing existing user_systems for user_id: #{user_id}...")
{deleted_count, _} = from(us in UserSystem, where: us.user_id == ^user_id)
|> Repo.delete_all()
IO.puts("  Deleted #{deleted_count} existing user_systems")

positions = [
  {100, 100},
  {300, 100},
  {200, 300},
  {100, 300}
]

IO.puts("\nCreating user_systems...")
Enum.each(Enum.with_index(all_systems), fn {system, index} ->
  {pos_x, pos_y} = Enum.at(positions, index) || {100, 100}

  user_system_attrs = %{
    user_id: user_id,
    system_id: system.id,
    status: "active",
    position_x: pos_x,
    position_y: pos_y,
    custom_notes: "Test system for Living Web visualization"
  }

  changeset = UserSystem.changeset(%UserSystem{}, user_system_attrs)

  case Repo.insert(changeset) do
    {:ok, user_system} ->
      IO.puts("  ✓ Created user_system: #{system.name} at (#{pos_x}, #{pos_y})")
    {:error, changeset} ->
      IO.puts("  ✗ Failed: #{inspect(changeset.errors)}")
  end
end)

# Verify created data
IO.puts("\n✅ Verification:")
user_systems = Repo.all(UserSystem)
IO.puts("  Total user_systems: #{length(user_systems)}")
Enum.each(user_systems, fn us ->
  system = Repo.preload(us, :system).system
  IO.puts("  • #{system.name} (id: #{us.id}) - Status: #{us.status}, Position: (#{us.position_x}, #{us.position_y})")
end)

IO.puts("\n🎉 Living Web test data seeding complete!\n")
