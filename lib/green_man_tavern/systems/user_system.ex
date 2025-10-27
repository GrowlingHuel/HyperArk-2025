defmodule GreenManTavern.Systems.UserSystem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_systems" do
    field :status, :string, default: "planned"
    field :position_x, :integer
    field :position_y, :integer
    field :custom_notes, :string
    field :location_notes, :string
    field :implemented_at, :utc_datetime_usec

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :system, GreenManTavern.Systems.System
  end

  @doc false
  def changeset(user_system, attrs) do
    user_system
    |> cast(attrs, [
      :user_id,
      :system_id,
      :status,
      :position_x,
      :position_y,
      :custom_notes,
      :location_notes,
      :implemented_at
    ])
    |> validate_required([:user_id, :system_id])
    |> validate_inclusion(:status, ["planned", "active", "inactive"])
    |> validate_length(:custom_notes, max: 2000)
    |> validate_length(:location_notes, max: 2000)
    |> sanitize_user_notes()
  end

  # Sanitize user-created notes to prevent XSS attacks
  defp sanitize_user_notes(changeset) do
    changeset
    |> sanitize_field(:custom_notes)
    |> sanitize_field(:location_notes)
  end

  defp sanitize_field(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      content when is_binary(content) ->
        # Escape HTML to prevent XSS
        sanitized = Phoenix.HTML.html_escape(content) |> Phoenix.HTML.safe_to_string()
        put_change(changeset, field, sanitized)

      _ ->
        changeset
    end
  end
end
