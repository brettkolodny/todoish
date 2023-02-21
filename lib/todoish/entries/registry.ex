defmodule Todoish.Entries.Registry do
  use Ash.Registry, extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry Todoish.Entries.List
    entry Todoish.Entries.Item
    entry Todoish.Entries.User
    entry Todoish.Entries.Token
  end
end
