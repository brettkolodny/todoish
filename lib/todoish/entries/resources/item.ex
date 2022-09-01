defmodule Todoish.Entries.Item do
	use Ash.Resource, data_layer: AshPostgres.DataLayer, notifiers: [Ash.Notifier.PubSub]

	postgres do
		table "items"
		repo Todoish.Repo
	end

	actions do
		defaults [:create, :read, :update, :destroy]

		create :new do
			accept [:title]

			argument :list_id, :uuid do
				allow_nil? false
			end

			change manage_relationship(:list_id, :list, type: :replace)
		end

		update :complete do
			accept []

			change set_attribute(:status, :completed)
		end

		update :incomplete do
			accept []

			change set_attribute(:status, :incompleted)
		end
	end

	attributes do
		uuid_primary_key :id

		timestamps()

		attribute :title, :string do
			allow_nil? false
		end

		attribute :status, :atom do
			constraints [one_of: [:completed, :incompleted]]

			default :incompleted

			allow_nil? false
		end
	end

	pub_sub do
		module TodoishWeb.Endpoint
		prefix "item"
		broadcast_type :phoenix_broadcast

		publish :new, ["list", :list_id], event: "item-added"
		publish :complete, ["list", :list_id], event: "item-updated"
		publish :incomplete, ["list", :list_id], event: "item-updated"
		publish :destroy, ["list", :list_id], event: "item-deleted"
	end

	relationships do
		belongs_to :list, Todoish.Entries.List
	end
end
