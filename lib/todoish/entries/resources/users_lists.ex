defmodule Todoish.Entries.UsersLists do
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  postgres do
    table "users_lists"
    repo Todoish.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :new do
      argument :list_id, :uuid do
        allow_nil? false
      end

      argument :user_id, :uuid do
        allow_nil? false
      end

      change manage_relationship(:list_id, :list, type: :replace)
      change manage_relationship(:user_id, :user, type: :replace)
    end
  end

  attributes do
    uuid_primary_key :id
  end

  relationships do
    belongs_to :list, Todoish.Entries.List do
      allow_nil? true
    end

    belongs_to :user, Todoish.Entries.User do
      allow_nil? true
    end
  end
end
