defmodule GreenManTavernWeb.UserSessionController do
  @moduledoc """
  Controller for user sessions (login/logout).
  Follows HyperCard aesthetic with greyscale styling.
  """

  use GreenManTavernWeb, :controller

  alias GreenManTavern.Accounts
  alias GreenManTavernWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    # TODO: Implement /users/settings route
    conn
    |> put_session(:user_return_to, ~p"/")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info_message) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info_message)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> render(:new, error_message: "Invalid email or password")
    end
  end

  def process_login(conn, params) do
    user_id = params["user_id"] || Phoenix.Flash.get(conn.assigns.flash, :user_id)

    if user_id do
      # Get the user and log them in
      user = Accounts.get_user!(user_id)

      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, %{})
    else
      # No temporary user data, redirect back to login
      conn
      |> put_flash(:error, "Login session expired. Please try again.")
      |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
    |> clear_session()
    |> redirect(to: ~p"/")
  end
end
