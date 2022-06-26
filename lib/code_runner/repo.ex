defmodule CodeRunner.Repo do
  use Ecto.Repo,
    otp_app: :code_runner,
    adapter: Ecto.Adapters.SQLite3
end
