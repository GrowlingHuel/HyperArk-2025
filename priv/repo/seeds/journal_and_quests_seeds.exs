# Journal and Quests Seed Data
import Ecto.Query
alias GreenManTavern.Repo
alias GreenManTavern.Accounts.User
alias GreenManTavern.Characters.Character
alias GreenManTavern.Journal
alias GreenManTavern.Quests
alias GreenManTavern.Quests.{Quest, UserQuest}
import Ecto.Changeset
import Bcrypt, only: [hash_pwd_salt: 1]

# Get or create a test user (adjust email as needed)
user = Repo.get_by(User, email: "jesse@testuser.com") ||
       Repo.insert!(%User{
         email: "jesse@testuser.com",
         hashed_password: hash_pwd_salt("password123"),
         confirmed_at: DateTime.utc_now()
       })

IO.puts("Creating seed data for user: #{user.email}")

# Get characters for quest assignment
grandmother = Repo.get_by(Character, name: "The Grandmother")
student = Repo.get_by(Character, name: "The Student")
farmer = Repo.get_by(Character, name: "The Farmer")

# Create journal entries
IO.puts("Creating journal entries...")

Journal.create_entry(%{
  user_id: user.id,
  entry_date: "1st of Last Seed",
  day_number: 1,
  title: "Beginning My Journey",
  body: "Today I discovered the Green Man Tavern and met its curious inhabitants. Each seems to hold knowledge that could help me build a sustainable homestead.",
  source_type: "manual_entry"
})

if grandmother do
  Journal.create_entry(%{
    user_id: user.id,
    entry_date: "3rd of Last Seed",
    day_number: 3,
    title: "Met The Grandmother",
    body: "The Grandmother shared wisdom about composting today. Her eyes sparkled as she described the transformation of kitchen scraps into rich, dark soil. She says the heat of a good compost pile can reach temperatures that kill weed seeds while nurturing beneficial microorganisms.",
    source_type: "character_conversation",
    source_id: grandmother.id
  })
end

Journal.create_entry(%{
  user_id: user.id,
  entry_date: "5th of Last Seed",
  day_number: 5,
  title: "First Compost Bin Built",
  body: "Using The Grandmother's guidance, I built my first compost bin from salvaged pallets. Started with layers of brown leaves and green kitchen scraps. The Grandmother nodded approvingly when I showed her the work.",
  source_type: "system_action"
})

Journal.create_entry(%{
  user_id: user.id,
  entry_date: "8th of Last Seed",
  day_number: 8,
  title: "Garden Planning",
  body: "Spent the day sketching garden layouts. Considering companion planting - tomatoes with basil, corn with beans and squash (the Three Sisters), marigolds around the edges to deter pests.",
  source_type: "manual_entry"
})

Journal.create_entry(%{
  user_id: user.id,
  entry_date: "12th of Last Seed",
  day_number: 12,
  title: "Understanding Closed Loops",
  body: "A revelation today: waste is just a resource in the wrong place. The kitchen scraps feed the compost, which feeds the garden, which feeds us. Each output becomes someone else's input. This is the essence of permaculture.",
  source_type: "manual_entry"
})

# Create quest templates
IO.puts("Creating quest templates...")

{:ok, quest1} = Quests.create_quest(%{
  character_id: grandmother && grandmother.id,
  title: "Start Traditional Composting",
  description: "Build a three-bin composting system using The Grandmother's time-tested method. Learn to balance greens and browns, maintain proper moisture, and turn the pile regularly.",
  difficulty: "easy",
  xp_reward: 30,
  quest_type: "implementation",
  steps: %{
    "steps" => [
      "Gather materials: pallets or lumber for bins",
      "Build three connected bins (turning, aging, finished)",
      "Start first pile with proper green/brown ratio",
      "Document the process in your journal"
    ]
  }
})

{:ok, quest2} = Quests.create_quest(%{
  character_id: student && student.id,
  title: "Learn About Companion Planting",
  description: "Research and document which plants grow well together and which should be kept apart. Create a companion planting guide for your garden.",
  difficulty: "easy",
  xp_reward: 25,
  quest_type: "learning",
  steps: %{
    "steps" => [
      "Research the Three Sisters (corn, beans, squash)",
      "Learn about beneficial herb companions",
      "Discover pest-deterring plant combinations",
      "Create your own companion planting chart"
    ]
  }
})

{:ok, quest3} = Quests.create_quest(%{
  character_id: farmer && farmer.id,
  title: "Build a Raised Bed",
  description: "Construct a raised garden bed to improve drainage and extend your growing season. The Farmer recommends starting with a 4x8 foot bed.",
  difficulty: "medium",
  xp_reward: 50,
  quest_type: "implementation",
  steps: %{
    "steps" => [
      "Choose location with 6-8 hours of sun",
      "Gather lumber and hardware",
      "Build the frame (4x8 feet recommended)",
      "Fill with quality soil mix",
      "Plant your first crops"
    ]
  }
})

{:ok, quest4} = Quests.create_quest(%{
  title: "Close Your First Loop",
  description: "Identify a waste stream in your household and turn it into a resource. This is a fundamental permaculture principle.",
  difficulty: "medium",
  xp_reward: 40,
  quest_type: "challenge",
  steps: %{
    "steps" => [
      "Audit your household waste for one week",
      "Identify one waste stream (food scraps, water, paper, etc.)",
      "Design a system to capture and reuse this resource",
      "Implement the system",
      "Document results in your journal"
    ]
  }
})

# Create user quest instances
IO.puts("Creating user quest instances...")

# Completed quest
{:ok, completed} = Quests.create_user_quest(user.id, quest1.id)
completed
|> change(%{
  status: "completed",
  started_at: DateTime.add(DateTime.utc_now(), -10, :day),
  completed_at: DateTime.add(DateTime.utc_now(), -3, :day),
  progress_data: %{"completed_steps" => [0, 1, 2, 3]}
})
|> Repo.update!()

# Active quest
{:ok, active} = Quests.create_user_quest(user.id, quest2.id)
active
|> change(%{
  status: "active",
  started_at: DateTime.add(DateTime.utc_now(), -2, :day),
  progress_data: %{"completed_steps" => [0, 1]}
})
|> Repo.update!()

# Available quests
Quests.create_user_quest(user.id, quest3.id)
Quests.create_user_quest(user.id, quest4.id)

IO.puts("✓ Created #{Repo.aggregate(Journal.Entry, :count, :id)} journal entries")
IO.puts("✓ Created #{Repo.aggregate(Quests.Quest, :count, :id)} quest templates")
IO.puts("✓ Created #{Repo.aggregate(Quests.UserQuest, :count, :id)} user quest instances")
IO.puts("\nSeed data complete! Login with: #{user.email} / password123")
