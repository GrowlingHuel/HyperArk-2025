defmodule GreenManTavernWeb.UserRegistrationLive do
  @moduledoc """
  LiveView for user registration.
  Follows HyperCard aesthetic with greyscale styling.
  """

  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Accounts
  alias GreenManTavern.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="auth-container">
      <div class="auth-window">
        <div class="auth-header">
          <h1 class="auth-title">Join the Tavern</h1>
          <p class="auth-subtitle">Create your account to begin your journey</p>
        </div>

        <.form
          for={@form}
          id="registration-form"
          phx-submit="save"
          phx-change="validate"
          class="auth-form"
        >
          <div class="form-group">
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              required
              class="form-input"
              placeholder="Enter your email"
            />
          </div>

          <div class="form-group">
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              required
              class="form-input"
              placeholder="Choose a password"
            />
          </div>

          <div class="form-group">
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirm Password"
              required
              class="form-input"
              placeholder="Confirm your password"
            />
          </div>

          <div class="form-actions">
            <button
              phx-disable-with="Creating account..."
              class="btn-primary"
              type="submit"
            >
              Create Account
            </button>
          </div>
        </.form>

        <div class="auth-footer">
          <p class="auth-link-text">
            Already have an account?
            <.link navigate={~p"/login"} class="auth-link">
              Sign in here
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(:is_auth_page, true)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        socket =
          socket
          |> put_flash(:info, "User created successfully. Please check your email for confirmation instructions.")
          |> Phoenix.LiveView.push_navigate(to: ~p"/")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
