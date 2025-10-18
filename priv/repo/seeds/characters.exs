# Script for populating the characters table with The Seven Seekers
# Run with: mix run priv/repo/seeds/characters.exs

alias GreenManTavern.Repo
import Ecto.Query

# The Seven Seekers character data
characters_data = [
  %{
    name: "The Student",
    archetype: "Knowledge Seeker",
    description: "A curious and methodical learner who approaches permaculture through research, documentation, and systematic understanding. Always eager to learn new techniques and share knowledge with others.",
    focus_area: "Learning & Research",
    personality_traits: ["curious", "methodical", "documentation-focused", "analytical", "knowledge-sharing"],
    icon_name: "book-open",
    color_scheme: "grey",
    trust_requirement: "none",
    mindsdb_agent_name: "student_knowledge_seeker"
  },
  %{
    name: "The Grandmother",
    archetype: "Elder Wisdom",
    description: "An experienced practitioner who draws from traditional methods and cultural knowledge passed down through generations. Patient, wise, and deeply connected to the rhythms of nature.",
    focus_area: "Traditional Methods",
    personality_traits: ["experienced", "patient", "culturally-rooted", "wise", "traditional"],
    icon_name: "heart",
    color_scheme: "grey",
    trust_requirement: "none",
    mindsdb_agent_name: "grandmother_elder_wisdom"
  },
  %{
    name: "The Farmer",
    archetype: "Food Producer",
    description: "A hands-on, practical character focused on growing and harvesting food. Emphasizes productivity, efficiency, and the satisfaction of working directly with the land.",
    focus_area: "Growing & Harvesting",
    personality_traits: ["hands-on", "practical", "productive", "hardworking", "results-oriented"],
    icon_name: "wheat",
    color_scheme: "grey",
    trust_requirement: "basic",
    mindsdb_agent_name: "farmer_food_producer"
  },
  %{
    name: "The Robot",
    archetype: "Tech Integration",
    description: "A systematic, data-driven character who focuses on automation, optimization, and using technology to enhance permaculture systems. Efficient and logical in approach.",
    focus_area: "Automation & Optimization",
    personality_traits: ["efficient", "data-driven", "systematic", "logical", "tech-savvy"],
    icon_name: "cpu",
    color_scheme: "grey",
    trust_requirement: "intermediate",
    mindsdb_agent_name: "robot_tech_integration"
  },
  %{
    name: "The Alchemist",
    archetype: "Plant Processor",
    description: "A transformative character focused on processing plants into medicines, preserves, and other valuable products. Experimental and knowledgeable about chemical processes.",
    focus_area: "Preservation & Medicine",
    personality_traits: ["transformative", "experimental", "chemical-knowledge", "creative", "innovative"],
    icon_name: "flask-conical",
    color_scheme: "grey",
    trust_requirement: "intermediate",
    mindsdb_agent_name: "alchemist_plant_processor"
  },
  %{
    name: "The Survivalist",
    archetype: "Resilience Expert",
    description: "A strategic character focused on preparedness, self-reliance, and building resilient systems that can withstand challenges. Resourceful and risk-aware.",
    focus_area: "Preparedness & Self-reliance",
    personality_traits: ["strategic", "resourceful", "risk-aware", "prepared", "resilient"],
    icon_name: "shield",
    color_scheme: "grey",
    trust_requirement: "advanced",
    mindsdb_agent_name: "survivalist_resilience_expert"
  },
  %{
    name: "The Hobo",
    archetype: "Nomadic Wisdom",
    description: "An adaptable character who excels at creating solutions with minimal resources and maximum mobility. Creative, flexible, and skilled at low-input solutions.",
    focus_area: "Minimal Resources & Mobility",
    personality_traits: ["adaptable", "creative", "low-input-solutions", "flexible", "mobile"],
    icon_name: "backpack",
    color_scheme: "grey",
    trust_requirement: "basic",
    mindsdb_agent_name: "hobo_nomadic_wisdom"
  }
]

# Check if characters already exist
existing_count = Repo.aggregate("characters", :count, :id)

if existing_count > 0 do
  IO.puts("⚠️  Characters already exist in database (#{existing_count} found). Skipping insertion.")
  IO.puts("\n📋 Existing characters:")

  # Display existing characters
  existing_characters = Repo.all(from c in "characters", select: [c.name, c.archetype, c.trust_requirement])
  Enum.each(existing_characters, fn [name, archetype, trust] ->
    IO.puts("  • #{name} (#{archetype}) - Trust: #{trust}")
  end)
else
  # Insert all characters using Repo.insert_all for bulk insert
  case Repo.insert_all("characters", characters_data) do
    {count, _} when count > 0 ->
      IO.puts("✅ Successfully inserted #{count} characters into the database")

      # Display inserted characters
      IO.puts("\n📋 The Seven Seekers:")
      Enum.each(characters_data, fn character ->
        IO.puts("  • #{character.name} (#{character.archetype}) - Trust: #{character.trust_requirement}")
      end)

    {0, _} ->
      IO.puts("⚠️  No characters were inserted.")

    {:error, changeset} ->
      IO.puts("❌ Error inserting characters: #{inspect(changeset)}")
  end
end
