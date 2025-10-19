defmodule GreenManTavern.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Bcrypt, only: [hash_pwd_salt: 1, verify_pass: 2, no_user_verify: 0]

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :profile_data, :map, default: %{}
    field :xp, :integer, default: 0
    field :level, :integer, default: 1

    belongs_to :primary_character, GreenManTavern.Characters.Character
    has_many :user_characters, GreenManTavern.Characters.UserCharacter
    has_many :user_systems, GreenManTavern.Systems.UserSystem
    has_many :user_quests, GreenManTavern.Quests.UserQuest
    has_many :user_achievements, GreenManTavern.Achievements.UserAchievement
    has_many :user_projects, GreenManTavern.Projects.UserProject
    has_many :conversations, GreenManTavern.Conversations.ConversationHistory

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  @doc """
  A user changeset for general updates.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :profile_data, :xp, :level, :primary_character_id])
    |> validate_email(validate_email: false)
    |> validate_number(:xp, greater_than_or_equal_to: 0)
    |> validate_number(:level, greater_than_or_equal_to: 1)
  end

  @doc """
  A user changeset for session (login).
  """
  def session_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
  end

  @doc """
  A user changeset for password changes.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:hashed_password])
    |> validate_confirmation(:hashed_password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.
  """
  def valid_password?(%GreenManTavern.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset
    |> put_change(:current_password, password)
    |> validate_change(:current_password, fn _, current_password ->
      case valid_password?(changeset.data, current_password) do
        true -> []
        false -> [current_password: "is not valid"]
      end
    end)
  end

  @doc """
  A user changeset for profile updates.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:profile_data, :xp, :level, :primary_character_id])
    |> validate_number(:xp, greater_than_or_equal_to: 0)
    |> validate_number(:level, greater_than_or_equal_to: 1)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      # If using Bcrypt, then further validate it is at most 72 bytes long
      if byte_size(password) > 72, do: raise(ArgumentError, "password should be at most 72 bytes long")

      changeset
      # If using Bcrypt, the `password` value will be hashed by `validate_password/2`
      |> put_change(:hashed_password, hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, GreenManTavern.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end
end
