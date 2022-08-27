defmodule Todoish.Entries do
	use Ash.Api

	resources do
		registry Todoish.Entries.Registry
	end
end
