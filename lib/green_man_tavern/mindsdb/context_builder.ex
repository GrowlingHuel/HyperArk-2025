defmodule GreenManTavern.MindsDB.ContextBuilder do
  @moduledoc """
  Builds user context data for injection into MindsDB agent queries.

  This module gathers relevant user data from the database and formats it
  for use in MindsDB agent queries. It handles missing data gracefully
  and works even if some tables don't exist yet.
  """

  import Ecto.Query, warn: false
  require Logger
  alias GreenManTavern.Repo
  alias GreenManTavern.Accounts
  alias GreenManTavern.Characters
  alias GreenManTavern.Systems

  @doc """
  Builds a comprehensive context map for a user.

  ## Parameters
  - `user_id` - The ID of the user to build context for

  ## Returns
  - A map containing user context data ready for MindsDB injection

  ## Example
      iex> ContextBuilder.build_context(1)
      %{
        user_location: "Zone 8b",
        user_space: "apartment",
        user_skill: "beginner",
        climate_zone: "Zone 8b",
        user_systems: ["herb_garden", "compost"],
        user_projects: ["chickens"],
        active_quests: 3,
        level: 5,
        xp: 847,
        character_trust: %{"The Student" => 75, "The Farmer" => 50}
      }
  """
  def build_context(user_id) when is_integer(user_id) do
    try do
      # Get user data
      user = Accounts.get_user!(user_id)

      # Extract profile data
      profile_data = user.profile_data || %{}

      # Get active systems
      active_systems = get_active_systems(user_id)

      # Get active projects (if table exists)
      active_projects = get_active_projects(user_id)

      # Get character relationships
      character_trust = get_character_relationships(user_id)

      # Get quest count
      active_quests = get_active_quest_count(user_id)

      # Build context map
      %{
        user_location: Map.get(profile_data, "climate_zone", ""),
        user_space: Map.get(profile_data, "space_type", ""),
        user_skill: Map.get(profile_data, "skill_level", "beginner"),
        climate_zone: Map.get(profile_data, "climate_zone", ""),
        user_systems: active_systems,
        user_projects: active_projects,
        active_quests: active_quests,
        level: user.level,
        xp: user.xp,
        character_trust: character_trust,
        primary_character: get_primary_character_name(user.primary_character_id)
      }
    rescue
      Ecto.NoResultsError ->
        Logger.warning("User #{user_id} not found for context building")
        build_empty_context()

      error ->
        Logger.error("Error building context for user #{user_id}: #{inspect(error)}")
        build_empty_context()
    end
  end

  def build_context(_), do: build_empty_context()

  @doc """
  Builds context for a specific character interaction.

  This version includes character-specific context data.
  """
  def build_character_context(user_id, character_id) when is_integer(user_id) and is_integer(character_id) do
    base_context = build_context(user_id)

    # Add character-specific data
    character_context = try do
      character = Characters.get_character!(character_id)
      %{
        character_name: character.name,
        character_archetype: character.archetype,
        character_focus: character.focus_area,
        character_trust_level: get_character_trust_level(user_id, character_id),
        character_requirements: character.trust_requirement
      }
    rescue
      Ecto.NoResultsError -> %{}
    end

    Map.merge(base_context, character_context)
  end

  def build_character_context(user_id, character_name) when is_integer(user_id) and is_binary(character_name) do
    case Characters.get_character_by_slug(character_name) do
      nil -> build_context(user_id)
      character -> build_character_context(user_id, character.id)
    end
  end

  def build_character_context(_, _), do: build_empty_context()

  # Private Functions

  defp get_active_systems(user_id) do
    try do
      from(us in Systems.UserSystem,
        join: s in Systems.System, on: us.system_id == s.id,
        where: us.user_id == ^user_id and us.status == "active",
        select: s.name
      )
      |> Repo.all()
    rescue
      _error ->
        Logger.warning("Could not fetch active systems for user #{user_id}")
        []
    end
  end

  defp get_active_projects(user_id) do
    try do
      # Check if user_projects table exists by attempting a query
      from(up in "user_projects",
        where: up.user_id == ^user_id and up.status != "abandoned",
        select: up.project_type
      )
      |> Repo.all()
    rescue
      _error ->
        # Table doesn't exist yet (Phase 3.1), return empty list
        Logger.info("user_projects table not available yet for user #{user_id}")
        []
    end
  end

  defp get_character_relationships(user_id) do
    try do
      from(uc in Characters.UserCharacter,
        join: c in Characters.Character, on: uc.character_id == c.id,
        where: uc.user_id == ^user_id,
        select: {c.name, uc.trust_level}
      )
      |> Repo.all()
      |> Map.new()
    rescue
      _error ->
        Logger.warning("Could not fetch character relationships for user #{user_id}")
        %{}
    end
  end

  defp get_character_trust_level(user_id, character_id) do
    try do
      case Characters.get_user_character(user_id, character_id) do
        nil -> 0
        user_character -> user_character.trust_level
      end
    rescue
      _error -> 0
    end
  end

  defp get_active_quest_count(user_id) do
    try do
      from(uq in "user_quests",
        where: uq.user_id == ^user_id and uq.status == "active"
      )
      |> Repo.aggregate(:count)
    rescue
      _error ->
        # Table doesn't exist yet, return 0
        0
    end
  end

  defp get_primary_character_name(nil), do: nil

  defp get_primary_character_name(character_id) do
    try do
      character = Characters.get_character!(character_id)
      character.name
    rescue
      _error -> nil
    end
  end

  defp build_empty_context do
    %{
      user_location: "",
      user_space: "",
      user_skill: "beginner",
      climate_zone: "",
      user_systems: [],
      user_projects: [],
      active_quests: 0,
      level: 1,
      xp: 0,
      character_trust: %{},
      primary_character: nil
    }
  end

  @doc """
  Caches context data for a user (optional optimization).

  This could be implemented with ETS or Redis for better performance.
  """
  def get_cached_context(user_id) do
    # For now, just rebuild context each time
    # TODO: Implement caching with 5-minute TTL
    build_context(user_id)
  end

  @doc """
  Invalidates cached context for a user.
  """
  def invalidate_context_cache(user_id) do
    # TODO: Implement cache invalidation
    Logger.info("Context cache invalidated for user #{user_id}")
    :ok
  end
end
