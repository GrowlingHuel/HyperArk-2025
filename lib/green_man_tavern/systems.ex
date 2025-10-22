defmodule GreenManTavern.Systems do
  @moduledoc """
  The Systems context.
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo

  alias GreenManTavern.Systems.System
  alias GreenManTavern.Systems.UserSystem
  alias GreenManTavern.Systems.Connection
  alias GreenManTavern.Systems.UserConnection

  @doc """
  Returns the list of all systems.
  """
  def list_systems do
    Repo.all(System)
  end

  @doc """
  Returns all systems ordered by category then name. No preloads.

  Matches Prompt 2: list_all_systems/0
  """
  def list_all_systems do
    from(s in System, order_by: [asc: s.category, asc: s.name])
    |> Repo.all()
  end

  @doc """
  Returns the list of systems filtered by category.
  """
  def list_systems_by_category(category) when is_binary(category) do
    from(s in System, where: s.category == ^category)
    |> Repo.all()
  end

  @doc """
  Returns a map of category => [systems]. Categories include:
  "food", "process", "storage", "water", "waste", "energy".

  Note: our schema uses "process" and "storage" as system_type, while
  the others are stored in the category field, so we compose accordingly.

  Matches Prompt 2: list_systems_by_category/0
  """
  def list_systems_by_category do
    systems = list_all_systems()

    %{
      "food" => Enum.filter(systems, &(&1.category == "food")),
      "water" => Enum.filter(systems, &(&1.category == "water")),
      "waste" => Enum.filter(systems, &(&1.category == "waste")),
      "energy" => Enum.filter(systems, &(&1.category == "energy")),
      "process" => Enum.filter(systems, &(&1.system_type == "process")),
      "storage" => Enum.filter(systems, &(&1.system_type == "storage"))
    }
  end

  @doc """
  Returns the list of systems filtered by space requirement.
  """
  def list_systems_by_space(space_type) when is_binary(space_type) do
    from(s in System, where: ilike(s.space_required, ^"%#{space_type}%"))
    |> Repo.all()
  end

  @doc """
  Gets a single system.
  """
  def get_system!(id), do: Repo.get!(System, id)

  @doc """
  Gets a single system by name.
  """
  def get_system_by_name(name) when is_binary(name) do
    Repo.get_by(System, name: name)
  end

  @doc """
  Creates a system.
  """
  def create_system(attrs \\ %{}) do
    %System{}
    |> System.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a system.
  """
  def update_system(%System{} = system, attrs) do
    system
    |> System.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a system.
  """
  def delete_system(%System{} = system) do
    Repo.delete(system)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking system changes.
  """
  def change_system(%System{} = system, attrs \\ %{}) do
    System.changeset(system, attrs)
  end

  # UserSystem functions

  @doc """
  Returns the list of user systems for a given user.
  """
  def list_user_systems(user_id) when is_integer(user_id) do
    from(us in UserSystem,
      where: us.user_id == ^user_id,
      preload: [:system]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of active user systems for a given user.
  """
  def list_active_user_systems(user_id) when is_integer(user_id) do
    from(us in UserSystem,
      where: us.user_id == ^user_id and us.status == "active",
      preload: [:system]
    )
    |> Repo.all()
  end

  @doc """
  Returns user's systems (active or planned) with position and notes.

  Includes joined system details. Security: filtered by user_id.

  Matches Prompt 2: get_user_systems/1
  """
  def get_user_systems(user_id) when is_integer(user_id) do
    from(us in UserSystem,
      where: us.user_id == ^user_id and us.status in ["active", "planned"],
      join: s in System, on: s.id == us.system_id,
      preload: [system: s],
      select: us
    )
    |> Repo.all()
  end

  @doc """
  Returns user's connections (active and potential) with from/to systems.

  Security: filtered by user_id.

  Matches Prompt 2: get_user_connections/1
  """
  def get_user_connections(user_id) when is_integer(user_id) do
    from(uc in UserConnection,
      where: uc.user_id == ^user_id and uc.status in ["active", "potential", "planned"],
      join: c in assoc(uc, :connection),
      left_join: fs in assoc(c, :from_system),
      left_join: ts in assoc(c, :to_system),
      preload: [connection: {c, from_system: fs, to_system: ts}]
    )
    |> Repo.all()
  end

  @doc """
  Creates a user_system at a position, with planned status.

  Matches Prompt 2: add_user_system/5
  """
  def add_user_system(user_id, system_id, x, y)
      when is_integer(user_id) and is_integer(system_id) and is_integer(x) and is_integer(y) do
    %UserSystem{}
    |> UserSystem.changeset(%{
      user_id: user_id,
      system_id: system_id,
      position_x: x,
      position_y: y,
      status: "planned",
      implemented_at: nil
    })
    |> Repo.insert()
  end

  @doc """
  Updates the position of an existing user_system.

  Matches Prompt 2: update_system_position/3
  """
  def update_system_position(user_system_id, x, y)
      when is_integer(user_system_id) and is_integer(x) and is_integer(y) do
    with %UserSystem{} = us <- Repo.get(UserSystem, user_system_id) do
      us
      |> UserSystem.changeset(%{position_x: x, position_y: y})
      |> Repo.update()
    else
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Deletes a user_system owned by the given user_id and cascades related
  user_connections for connections that involve the deleted system.

  Matches Prompt 2: delete_user_system/2
  """
  def delete_user_system(user_system_id, user_id)
      when is_integer(user_system_id) and is_integer(user_id) do
    case Repo.get(UserSystem, user_system_id) do
      %UserSystem{user_id: ^user_id, system_id: system_id} = us ->
        # Delete user_connections that reference connections involving this system
        from(uc in UserConnection,
          where: uc.user_id == ^user_id,
          join: c in Connection, on: c.id == uc.connection_id,
          where: c.from_system_id == ^system_id or c.to_system_id == ^system_id
        )
        |> Repo.delete_all()

        Repo.delete(us)

      %UserSystem{} ->
        {:error, :unauthorized}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets a single user system.
  """
  def get_user_system!(id), do: Repo.get!(UserSystem, id)

  @doc """
  Gets a user system by user and system IDs.
  """
  def get_user_system_by_user_and_system(user_id, system_id) when is_integer(user_id) and is_integer(system_id) do
    Repo.get_by(UserSystem, user_id: user_id, system_id: system_id)
  end

  @doc """
  Creates a user system.
  """
  def create_user_system(attrs \\ %{}) do
    %UserSystem{}
    |> UserSystem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user system.
  """
  def update_user_system(%UserSystem{} = user_system, attrs) do
    user_system
    |> UserSystem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user system.
  """
  def delete_user_system(%UserSystem{} = user_system) do
    Repo.delete(user_system)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user system changes.
  """
  def change_user_system(%UserSystem{} = user_system, attrs \\ %{}) do
    UserSystem.changeset(user_system, attrs)
  end

  @doc """
  Groups systems by category for display.
  """
  def group_systems_by_category(systems) do
    systems
    |> Enum.group_by(& &1.category)
    |> Enum.map(fn {category, systems} ->
      {category, Enum.sort_by(systems, & &1.name)}
    end)
    |> Enum.sort_by(fn {category, _} -> category end)
  end

  @doc """
  Filters systems by user's space type.
  """
  def filter_systems_by_space(systems, user_space_type) when is_binary(user_space_type) do
    Enum.filter(systems, fn system ->
      String.contains?(system.space_required, user_space_type)
    end)
  end

  @doc """
  Gets category display name and color.
  """
  def get_category_info(category) do
    case category do
      "food" -> {"Food Production", "#CCCCCC"}
      "water" -> {"Water Systems", "#BBBBBB"}
      "waste" -> {"Waste Cycling", "#AAAAAA"}
      "energy" -> {"Energy Systems", "#999999"}
      _ -> {String.capitalize(category), "#DDDDDD"}
    end
  end
end
