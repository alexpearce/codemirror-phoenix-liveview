defmodule CodeRunner.Snippet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "snippets" do
    field :content, :string
    field :language, :string

    timestamps()
  end

  @doc false
  def changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:content, :language])
    |> validate_required([:content, :language])
  end
end
