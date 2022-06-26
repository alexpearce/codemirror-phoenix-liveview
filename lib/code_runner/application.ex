defmodule CodeRunner.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      CodeRunner.Repo,
      # Start the Telemetry supervisor
      CodeRunnerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CodeRunner.PubSub},
      # Start the Endpoint (http/https)
      CodeRunnerWeb.Endpoint
      # Start a worker by calling: CodeRunner.Worker.start_link(arg)
      # {CodeRunner.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CodeRunner.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CodeRunnerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
