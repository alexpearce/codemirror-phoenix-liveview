defmodule CodeRunnerWeb.PageController do
  use CodeRunnerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
