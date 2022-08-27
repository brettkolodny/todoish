defmodule Todoish.Entries.List do
	use Ash.Resource, data_layer: Ash.DataLayer.Ets

	actions do
		defaults [:create, :read, :update, :destroy]

		create :new do
			accept [:title, :url_id]
		end
	end

	attributes do
		uuid_primary_key :id

		attribute :title, :string do
			allow_nil? false
		end

		attribute :url_id, :string do
			allow_nil? false
		end
	end

	relationships do
		has_many :items, Todoish.Entries.Item
	end
end
