defmodule GreenManTavern.Characters do
  @moduledoc """
  The Characters context for managing AI character data and relationships.

  This module provides functions for managing the seven seeker characters
  (The Student, The Grandmother, The Farmer, The Robot, The Alchemist,
  The Survivalist, and The Hobo) and their relationships with users.

  ## Features

  - Character data management (get, create, update, delete)
  - User-character relationship tracking (trust levels, interactions)
  - Slug generation for URL-friendly character names
  - Trust system for character access control

  ## Security

  - All queries are properly scoped by user_id
  - Trust level verification for character access
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  alias GreenManTavern.Characters.Character
  alias GreenManTavern.Characters.UserCharacter

  @doc """
  Returns the list of characters.

  ## Examples

      iex> list_characters()
      [%Character{}, ...]

  """
  def list_characters do
    Repo.all(from c in Character, order_by: [asc: c.name])
  end

  @doc """
  Gets a single character.

  Raises `Ecto.NoResultsError` if the Character does not exist.

  ## Examples

      iex> get_character!(123)
      %Character{}

      iex> get_character!(456)
      ** (Ecto.NoResultsError)

  """
  def get_character!(id), do: Repo.get!(Character, id)

  @doc """
  Gets a character by name.

  ## Examples

      iex> get_character_by_name("The Grandmother")
      %Character{}

      iex> get_character_by_name("Non-existent")
      nil

  """
  def get_character_by_name(name) do
    Repo.get_by(Character, name: name)
  end

  @doc """
  Gets a character by slug (URL-friendly name).

  ## Examples

      iex> get_character_by_slug("the-grandmother")
      %Character{}

      iex> get_character_by_slug("non-existent")
      nil

  """
  def get_character_by_slug(slug) do
    # Convert URL-friendly name back to proper name
    proper_name =
      slug
      |> String.replace("-", " ")
      |> String.split(" ")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    get_character_by_name(proper_name)
  end

  @doc """
  Creates a character.

  ## Examples

      iex> create_character(%{field: value})
      {:ok, %Character{}}

      iex> create_character(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a character.

  ## Examples

      iex> update_character(character, %{field: new_value})
      {:ok, %Character{}}

      iex> update_character(character, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_character(%Character{} = character, attrs) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a character.

  ## Examples

      iex> delete_character(character)
      {:ok, %Character{}}

      iex> delete_character(character)
      {:error, %Ecto.Changeset{}}

  """
  def delete_character(%Character{} = character) do
    Repo.delete(character)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking character changes.

  ## Examples

      iex> change_character(character)
      %Ecto.Changeset{data: %Character{}}

  """
  def change_character(%Character{} = character, attrs \\ %{}) do
    Character.changeset(character, attrs)
  end

  @doc """
  Converts a character name to a URL-friendly slug.

  ## Examples

      iex> name_to_slug("The Grandmother")
      "the-grandmother"

      iex> name_to_slug("The Student")
      "the-student"

  """
  def name_to_slug(name) do
    name
    |> String.downcase()
    |> String.replace(" ", "-")
  end

  # Trust System Functions

  @doc """
  Gets or creates a user-character relationship.

  Returns the existing relationship if found, otherwise creates a new one
  with default trust level of 0.

  ## Parameters

  - `user_id` - The user's ID (integer, required)
  - `character_id` - The character's ID (integer, required)

  ## Returns

  - `{:ok, %UserCharacter{}}` - The relationship struct

  ## Examples

      iex> get_or_create_user_character(1, 2)
      {:ok, %UserCharacter{user_id: 1, character_id: 2, trust_level: 0}}

  """
  def get_or_create_user_character(user_id, character_id) do
    case get_user_character(user_id, character_id) do
      nil -> create_user_character(%{user_id: user_id, character_id: character_id})
      user_character -> {:ok, user_character}
    end
  end

  @doc """
  Gets a user-character relationship by user and character IDs.

  Returns the relationship if it exists, otherwise returns `nil`.

  ## Parameters

  - `user_id` - The user's ID (integer, required)
  - `character_id` - The character's ID (integer, required)

  ## Returns

  - `%UserCharacter{}` - The relationship struct if found
  - `nil` - If no relationship exists

  ## Examples

      iex> get_user_character(1, 2)
      %UserCharacter{user_id: 1, character_id: 2, trust_level: 25}

      iex> get_user_character(1, 999)
      nil

  """
  def get_user_character(user_id, character_id) do
    from(uc in UserCharacter,
      where: uc.user_id == ^user_id and uc.character_id == ^character_id
    )
    |> Repo.one()
  end

  @doc """
  Creates a user-character relationship.

  ## Examples

      iex> create_user_character(%{user_id: 1, character_id: 2})
      {:ok, %UserCharacter{}}

      iex> create_user_character(%{user_id: 1, character_id: 2})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_character(attrs \\ %{}) do
    %UserCharacter{}
    |> UserCharacter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user-character relationship.

  ## Examples

      iex> update_user_character(user_character, %{trust_level: 50})
      {:ok, %UserCharacter{}}

      iex> update_user_character(user_character, %{trust_level: -1})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_character(%UserCharacter{} = user_character, attrs) do
    user_character
    |> UserCharacter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's trust level with a character.

  Gets or creates the user-character relationship, then increases
  the trust level by the specified delta.

  ## Parameters

  - `user_id` - The user's ID (integer, required)
  - `character_id` - The character's ID (integer, required)
  - `trust_delta` - The amount to increase trust (positive number)

  ## Returns

  - `{:ok, %UserCharacter{}}` - Updated relationship
  - `{:error, %Ecto.Changeset{}}` - If validation fails

  ## Examples

      iex> update_user_character_trust(1, 2, 5)
      {:ok, %UserCharacter{trust_level: 30}}

      iex> update_user_character_trust(1, 2, -10)
      {:error, %Ecto.Changeset{}}

  """
  def update_user_character_trust(user_id, character_id, trust_delta) do
    case get_or_create_user_character(user_id, character_id) do
      {:ok, user_character} ->
        user_character
        |> UserCharacter.increase_trust(trust_delta)
        |> Repo.update()

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Gets all user-character relationships for a user.

  ## Examples

      iex> get_user_character_relationships(1)
      [%UserCharacter{}, ...]

  """
  def get_user_character_relationships(user_id) do
    from(uc in UserCharacter,
      where: uc.user_id == ^user_id,
      preload: [:character],
      order_by: [desc: uc.trust_level]
    )
    |> Repo.all()
  end

  @doc """
  Gets all user-character relationships for a character.

  ## Examples

      iex> get_character_user_relationships(1)
      [%UserCharacter{}, ...]

  """
  def get_character_user_relationships(character_id) do
    from(uc in UserCharacter,
      where: uc.character_id == ^character_id,
      preload: [:user],
      order_by: [desc: uc.trust_level]
    )
    |> Repo.all()
  end

  @doc """
  Checks if a user has sufficient trust with a character.

  ## Examples

      iex> has_sufficient_trust?(1, 2)
      true

  """
  def has_sufficient_trust?(user_id, character_id) do
    case get_user_character(user_id, character_id) do
      nil -> false
      user_character -> user_character.is_trusted
    end
  end

  @doc """
  Gets the trust level between a user and character.

  ## Examples

      iex> get_trust_level(1, 2)
      25

  """
  def get_trust_level(user_id, character_id) do
    case get_user_character(user_id, character_id) do
      nil -> 0
      user_character -> user_character.trust_level
    end
  end
end
