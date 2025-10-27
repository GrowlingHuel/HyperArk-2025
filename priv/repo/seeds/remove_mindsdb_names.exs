# Script to remove MindsDB agent names from characters
alias GreenManTavern.Repo
import Ecto.Query

IO.puts("\n🔧 Removing MindsDB agent names from characters...\n")

{count, _} = Repo.update_all(
  from(c in "characters"),
  set: [mindsdb_agent_name: nil]
)

IO.puts("✅ Updated #{count} characters")
IO.puts("\nVerified:")
Repo.all(from c in "characters", select: [:name, :mindsdb_agent_name])
|> Enum.each(fn %{name: name, mindsdb_agent_name: agent} ->
  IO.puts("  • #{name}: mindsdb_agent_name = #{agent}")
end)

IO.puts("\n🎉 Done!\n")
