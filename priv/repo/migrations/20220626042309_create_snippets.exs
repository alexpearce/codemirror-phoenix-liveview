defmodule CodeRunner.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :content, :text
      add :language, :string

      timestamps()
    end
  end
end
