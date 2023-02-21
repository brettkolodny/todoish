defmodule Todoish.Entries.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  token do
    api Todoish.Entries
  end

  postgres do
    table "tokens"
    repo Todoish.Repo
  end
end
