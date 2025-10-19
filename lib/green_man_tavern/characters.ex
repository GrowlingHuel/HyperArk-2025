defmodule GreenManTavern.Characters do
  @moduledoc """
  The Characters context.
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  alias GreenManTavern.Characters.Character

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
    proper_name = slug
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
end
