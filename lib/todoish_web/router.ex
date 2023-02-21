defmodule TodoishWeb.Router do
  use TodoishWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TodoishWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", TodoishWeb do
    pipe_through :browser

    get "/", PageController, :index

    post "/", PageController, :new

    sign_in_route()
    sign_out_route AuthController
    auth_routes_for Todoish.Entries.User, to: AuthController
    reset_route []

    live "/:url_id", Live.List
  end

  # Other scopes may use custom stacks.
  # scope "/api", TodoishWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TodoishWeb.Telemetry
    end
  end
end
