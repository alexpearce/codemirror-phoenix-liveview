defmodule CodeRunnerWeb.Live.SnippetExecutionLiveTest do
  use CodeRunnerWeb.ConnCase
  import Phoenix.LiveViewTest
  alias CodeRunnerWeb.Live.SnippetExecutionLive

  defp create_snippet(params) do
    SnippetExecutionLive.create_snippet(params)
  end

  test "initial empty snippet", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view
      |> has_element?("#snippet_content", ~r"^\n$")
  end

  test "initial populated snippet", %{conn: conn} do
    {:ok, snippet} = create_snippet(%{content: "Test snippet", language: "python"})
    {:ok, view, _html} = live(conn, "/")

    assert view
      |> has_element?("#snippet_content", snippet.content)
  end

  test "initial populated latest snippet", %{conn: conn} do
    {:ok, _snippet} = create_snippet(%{content: "Test snippet 1", language: "python"})
    # Sleep so the second snippet has a different inserted_at timestamp value
    Process.sleep(1_000)
    {:ok, snippet} = create_snippet(%{content: "Test snippet 2", language: "elixir"})
    {:ok, view, _html} = live(conn, "/")

    assert view
      |> has_element?("#snippet_content", snippet.content)
    assert view
      |> has_element?("#snippet_language option[value=\"elixir\"][selected]")
  end

  test "empty snippet is invalid", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view
      |> form("form")
      |> render_submit() =~ "can&#39;t be blank"
  end

  test "non-empty snippet is valid", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view
      |> form("form", %{"snippet[content]": "Test submission"})
      |> render_submit() =~ "Snippet created. Running…"
  end

  test "submitted snippet is persisted", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    content = "Test submission"
    view
      |> form("form", %{"snippet[content]": content})
      |> render_submit()

    assert has_element?(view, "#snippet_content", content)
  end

  test "renders logs", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    Process.send(view.pid, {:log, %{content: "Test log"}}, [])

    assert view
      |> has_element?("code", "Test log")
  end


  test "submitted snippet starts log streaming process", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view
      |> form("form", %{"snippet[content]": "Test submission"})
      |> render_submit() =~ "Running snippet #1…"
  end
end
