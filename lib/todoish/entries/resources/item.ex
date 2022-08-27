defmodule Todoish.Entries.Item do
	use Ash.Resource, data_layer: Ash.DataLayer.Ets, notifiers: [Ash.Notifier.PubSub]

	actions do
		defaults [:create, :read, :update, :destroy]

		create :new do
			accept [:title]
		end

		update :add do
			accept []

			argument :list_id, :uuid do
				allow_nil? false
			end

			change manage_relationship(:list_id, :list, type: :replace)
		end
	end

	attributes do
		uuid_primary_key :id

		timestamps()

		attribute :description, :string

		attribute :title, :string do
			allow_nil? false
		end

		attribute :status, :atom do
			constraints [one_of: [:open, :closed]]

			default :open

			allow_nil? false
		end
	end

	pub_sub do
		module TodoishWeb.Endpoint
		prefix "item"
		broadcast_type :phoenix_broadcast

		publish :add, ["list", :list_id], event: "item-added"
	end

	relationships do
		belongs_to :list, Todoish.Entries.List
	end
end
