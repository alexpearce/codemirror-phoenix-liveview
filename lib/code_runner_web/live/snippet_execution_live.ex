defmodule CodeRunnerWeb.Live.SnippetExecutionLive do
  use CodeRunnerWeb, :live_view
  import Ecto.Query, only: [from: 2]
  alias CodeRunner.Repo
  alias CodeRunner.Snippet

  @default_language "python"
  @log_interval 1_000

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_initial_changeset()
      |> assign(:running, false)
      |> assign(:logs, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h2>Snippet</h2>
    <div id="editor" phx-update="ignore"></div>
    <.form let={f} for={@changeset} phx-submit="create">
      <%= label f, :content do %>
        Content
        <%= textarea f, :content, phx_hook: "EditorForm", style: "display: none;" %>
        <%= error_tag f, :content %>
      <% end %>
      <%= label f, :language do %>
        Language
        <%= select f, :language, ["Elixir": "elixir", "Python": "python"], prompt: [key: "Language", disabled: true] %>
        <%= error_tag f, :language %>
      <% end %>
      <%= submit "Submit", disabled: @running %>
    </.form>
    <h2>Logs</h2>
    <%= if Enum.empty?(@logs) do %>
      <p>Waiting for snippet submission.</p>
    <% else %>
      <pre><code><%= for line <- Enum.reverse(@logs) do %><%= line %>
    <% end %></code></pre>
    <% end %>
    """
  end

  def handle_event("create", %{"snippet" => params}, socket) do
    case create_snippet(params) do
      {:ok, record} ->
        # Start the dummy 'code execution' process, subscribing to the messages
        # it will broadcast
        channel = "#{record.id}"
        CodeRunnerWeb.Endpoint.subscribe(channel)
        Process.send_after(self(), {:log, channel, 5}, @log_interval)

        {:noreply,
         socket
         |> assign(changeset: record |> Snippet.changeset(%{}))
         |> assign(running: true)
         |> assign(logs: ["Running snippet ##{record.id}…"])
         |> put_flash(:info, "Snippet created. Running…")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> clear_flash}
    end
  end

  def handle_info({:log, %{content: log}}, socket) do
    {:noreply, update(socket, :logs, fn logs -> [log | logs] end)}
  end

  def handle_info(:done, socket) do
    {:noreply, assign(socket, running: false) |> clear_flash}
  end

  def handle_info({:log, channel, 0}, state) do
    Phoenix.PubSub.broadcast(
      CodeRunner.PubSub,
      channel,
      {:log, %{content: "Done!"}}
    )

    Phoenix.PubSub.broadcast(
      CodeRunner.PubSub,
      channel,
      :done
    )

    {:noreply, state}
  end

  def handle_info({:log, channel, num}, state) do
    Process.send_after(self(), {:log, channel, num - 1}, @log_interval)

    Phoenix.PubSub.broadcast(
      CodeRunner.PubSub,
      channel,
      {:log, %{content: "T-minus #{num}"}}
    )

    {:noreply, state}
  end

  def create_snippet(params) do
    %Snippet{}
    |> Snippet.changeset(params)
    |> Repo.insert()
  end

  defp assign_initial_changeset(socket) do
    # Assign a changeset to the most recent snippet, if one exists, or a new snippet.
    query =
      from(s in Snippet,
        order_by: [desc: s.inserted_at],
        limit: 1
      )

    changeset =
      case Repo.one(query) do
        nil -> %Snippet{language: @default_language}
        record -> %Snippet{content: record.content, language: record.language}
      end
      |> Snippet.changeset(%{})

    socket |> assign(changeset: changeset)
  end
end
