defmodule Todoish.Entries.List do
  use Ash.Resource, data_layer: AshPostgres.DataLayer, notifiers: [Ash.Notifier.PubSub]

  postgres do
    table("lists")
    repo(Todoish.Repo)
  end

  actions do
    defaults([:create, :read, :update, :destroy])

    create :new do
      accept([:title, :url_id, :description])
    end
  end

  attributes do
    uuid_primary_key(:id)

    timestamps()

    attribute :title, :string do
      default("A Todoish List")

      # allow_nil? false
    end

    attribute :description, :string do
      default("Add items to get started!")

      # allow_nil? false
    end

    attribute :url_id, :string do
      allow_nil?(false)
    end

    identities do
      identity(:unique_url_id, [:url_id], pre_check_with: Todoish.Entries)
    end
  end

  pub_sub do
    module(TodoishWeb.Endpoint)
    prefix("list")
    broadcast_type(:notification)

    publish(:new, ["created"], event: "new-list")
  end

  relationships do
    has_many :items, Todoish.Entries.Item

    many_to_many :users, Todoish.Entries.User do
      through(Todoish.Entries.UsersLists)
      source_attribute_on_join_resource(:list_id)
      destination_attribute_on_join_resource(:user_id)
    end
  end
end
