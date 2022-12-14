defmodule Todoish.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TodoishWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Todoish.PubSub},
      # Start the Endpoint (http/https)
      TodoishWeb.Endpoint,
      # Start a worker by calling: Todoish.Worker.start_link(arg)
      # {Todoish.Worker, arg}
      Todoish.Repo,
      {Todoish.EntriesServer, name: :entries_server}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Todoish.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TodoishWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
