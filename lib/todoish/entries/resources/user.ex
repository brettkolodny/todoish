defmodule Todoish.Entries.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
  end

  authentication do
    api Todoish.Entries

    strategies do
      password :password do
        identity_field(:email)
      end
    end

    tokens do
      enabled?(true)
      token_resource(Todoish.Entries.Token)

      signing_secret(Application.compile_env(:todoish, TodoishWeb.Endpoint)[:secret_key_base])
    end
  end

  actions do
    defaults [:read]
  end

  relationships do
    many_to_many :lists, Todoish.Entries.List do
      through Todoish.Entries.UsersLists
      source_attribute_on_join_resource :user_id
      destination_attribute_on_join_resource :list_id
    end
  end

  postgres do
    table "users"
    repo Todoish.Repo
  end

  identities do
    identity :unique_email, [:email]
  end
end
