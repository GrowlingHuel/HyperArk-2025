defmodule GreenManTavernWeb.Router do
  use GreenManTavernWeb, :router

  import GreenManTavernWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GreenManTavernWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Routes for unauthenticated users
  scope "/", GreenManTavernWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/register", UserRegistrationLive, :new
    post "/register", UserRegistrationController, :create
    live "/login", UserSessionLive, :new
    post "/login", UserSessionController, :create
    get "/login/process", UserSessionController, :process_login
  end

  # Routes for authenticated users
  scope "/", GreenManTavernWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{GreenManTavernWeb.UserAuth, :ensure_authenticated}] do

      live "/", HomeLive
      live "/characters/:character_name", CharacterLive
      live "/living-web", LivingWebLive
    end
  end

  # Public routes (no authentication required)
  scope "/", GreenManTavernWeb do
    pipe_through :browser

    delete "/logout", UserSessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", GreenManTavernWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:green_man_tavern, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GreenManTavernWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
