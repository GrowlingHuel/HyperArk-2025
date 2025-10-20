defmodule GreenManTavernWeb.UserSessionLive do
  @moduledoc """
  LiveView for user sessions (login).
  Follows HyperCard aesthetic with greyscale styling.
  """

  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Accounts

  def render(assigns) do
    ~H"""
    <div class="auth-container">
      <div class="auth-window">
        <div class="auth-header">
          <h1 class="auth-title">Welcome Back</h1>
          <p class="auth-subtitle">Sign in to continue your journey</p>
        </div>

        <.form
          for={@form}
          id="login-form"
          phx-submit="save"
          phx-change="validate"
          phx-hook="redirect"
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
              value={@email}
            />
          </div>

          <div class="form-group">
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              required
              class="form-input"
              placeholder="Enter your password"
            />
          </div>

          <div class="form-group">
            <label class="checkbox-label">
              <.input
                field={@form[:remember_me]}
                type="checkbox"
                class="checkbox-input"
              />
              <span class="checkbox-text">Remember me</span>
            </label>
          </div>

          <div class="form-actions">
            <button
              phx-disable-with="Signing in..."
              class="btn-primary"
              type="submit"
            >
              Sign In
            </button>
          </div>
        </.form>

        <div class="auth-footer">
          <p class="auth-link-text">
            Don't have an account?
            <.link navigate={~p"/register"} class="auth-link">
              Create one here
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    changeset = Accounts.change_user_session(%{})

    socket =
      socket
      |> assign(:is_auth_page, true)
      |> assign(:form, to_form(changeset, as: "user"))
      |> assign(:email, email)

    {:ok, socket}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_session(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Store user info in session and redirect to controller to set session
        socket =
          socket
          |> put_flash(:info, "Welcome back!")
          |> Phoenix.LiveView.push_event("redirect", %{to: "/login/process?user_id=#{user.id}"})

        {:noreply, socket}

      {:error, :invalid_credentials} ->
        # Show an error without clearing the form
        changeset =
          Accounts.change_user_session(user_params)
          |> Map.put(:action, :insert)
          |> add_error(:email, "Invalid email or password")

        {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
    end
  end

  defp add_error(changeset, field, message) do
    %{changeset | errors: [{field, {message, []}} | changeset.errors]}
  end
end
