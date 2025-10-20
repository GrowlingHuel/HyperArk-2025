defmodule GreenManTavern.Accounts do
  @moduledoc """
  The Accounts context for managing users and authentication.
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  alias GreenManTavern.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("user@example.com")
      %User{}

      iex> get_user_by_email("nonexistent@example.com")
      nil

  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Updates user's trust level with a character.

  ## Parameters
  - `user_id` - The ID of the user
  - `character_id` - The ID of the character
  - `trust_delta` - The amount to change the trust level by

  ## Returns
  - `{:ok, result}` - Success with result
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> update_user_character_trust(1, 2, 5)
      {:ok, %{}}

  """
  def update_user_character_trust(user_id, character_id, trust_delta) do
    # For now, just log the trust update
    IO.puts("Updating trust: user #{user_id}, character #{character_id}, delta #{trust_delta}")
    {:ok, %{}}
  end

  @doc """
  Authenticates a user with email and password.

  ## Examples

      iex> authenticate_user("user@example.com", "password")
      {:ok, %User{}}

      iex> authenticate_user("user@example.com", "wrong_password")
      {:error, :invalid_credentials}

  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    if user && User.valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("user@example.com", "password")
      %User{}

      iex> get_user_by_email_and_password("user@example.com", "wrong_password")
      nil

  """
  def get_user_by_email_and_password(email, password) do
    user = get_user_by_email(email)
    if user && User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a user by session token.
  """
  def get_user_by_session_token(token) do
    # Extract user ID from token format: "session_#{user_id}_#{unique_integer}"
    case String.split(token, "_") do
      ["session", user_id_str, _unique_integer] ->
        case Integer.parse(user_id_str) do
          {user_id, ""} -> get_user!(user_id)
          _ -> nil
        end
      _ -> nil
    end
  end

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    # For now, return a simple token - implement proper session tokens later
    "session_#{user.id}_#{System.unique_integer([:positive])}"
  end

  @doc """
  Deletes a session token.
  """
  def delete_session_token(_token) do
    # For now, just return :ok - implement session token deletion later
    :ok
  end

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{email: "user@example.com", password: "password"})
      {:ok, %User{}}

      iex> register_user(%{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs, opts \\ []) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert(opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for user registration.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: true, validate_email: true)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for user session.

  ## Examples

      iex> change_user_session(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_session(attrs \\ %{}) do
    User.session_changeset(%User{}, attrs)
  end

  @doc """
  Delivers user confirmation instructions.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/\#{&1}"))
      {:ok, %{to: "user@example.com", subject: "Confirmation instructions"}}

  """
  def deliver_user_confirmation_instructions(user, _url_fun) do
    # For now, just return success - implement email delivery later
    {:ok, %{to: user.email, subject: "Confirmation instructions"}}
  end
end
