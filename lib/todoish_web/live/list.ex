defmodule TodoishWeb.Live.List do
  use Phoenix.LiveView
	use Phoenix.HTML

  require Ash.Query

  def render(assigns) do
		~L"""
		<div class="flex flex-col justify-center items-center gap-6 w-screen mt-4">
			<div class="flex flex-col justify-center items-center gap-1 md:gap-2">
				<h1 class="flex flex-row justify-start items-center">
						<div class="font-bold text-3xl md:text-6xl text-base-900"><%= @list.title %></div>
						<div class="text-base md:text-2xl transform -translate-y-2">✅</div>
				</h1>
				<h2 class="text-lg text-center">
					<%= @list.description %>
				</h2>
			</div>
			<div class="flex flex-col justify-center items-center gap-4 w-full max-w-xs md:max-w-lg bg-white px-4 md:px-8 py-6 md:py-10 rounded-lg border border-base-300">
				<%= for item <- Enum.reverse(@list.items) do %>
					<div class="flex flex-row justify-center items-center gap-2 w-full">
						<div class="w-6 cursor-pointer text-xl text-center" phx-click="delete" phx-value-id="<%= item.id %>">🗑️</div>
						<div class="flex justify-start items-center w-56 md:w-96 min-h-min py-3 pl-4 text-sm md:text-base rounded-md bg-base-50 border border-base-200 <%= if item.status == :completed, do: "opacity-30"%>">
							<%= item.title %>
						</div>
						<div class="w-6 text-xl text-center cursor-pointer" phx-click="done" phx-value-id="<%= item.id %>">
							<%= if item.status == :incompleted do %>
								✅
							<% else %>
								🔁
							<% end %>
						</div>
					</div>
				<% end %>
				<%= f = form_for @form, "#", [phx_submit: :save, phx_change: :validate, class: "flex flex-row justify-center w-full gap-2"] %>
					<div class="flex justify-center items-center w-6"></div>
					<%= text_input f, :title, [id: "new-todo", placeholder: "More pizza!", class: ["w-56 md:w-96 h-12 text-sm md:text-base rounded-md bg-base-100"]] %>
					<%= submit "➕", [class: ["w-6 text-xl"]] %>
				</form>
				<div class="mb-8">
					<%= if @error != nil do %>
						<div class="flex flex-row items-center w-56 md:w-96 h-12 px-4 md:px-6 rounded-md bg-red-100 text-sm md:text-base"><%= @error %></div>
					<% end %>
				</div>
				<div phx-click="share" id="share-button" class="flex justify-center items-center w-56 md:w-96 bg-primary-400 text-white h-12 text-base md:text-lg rounded-md hover:bg-primary-500 transition-colors cursor-pointer">Share this list!</div>
			</div>
		</div>
		"""
  end

  def mount(%{"url_id" => url_id}, _sessions, socket) do
		list = Todoish.Entries.List
	  	|> Ash.Query.filter(url_id == ^url_id)
	  	|> Ash.Query.limit(1)
	  	|> Ash.Query.select([:title, :id, :url_id, :description])
			|> Ash.Query.load([items: Ash.Query.sort(Todoish.Entries.Item, inserted_at: :desc)])
	  	|> Todoish.Entries.read_one!()

		if list != nil do
			TodoishWeb.Endpoint.subscribe("item:list:#{list.id}")

			form = AshPhoenix.Form.for_create(
				Todoish.Entries.Item,
				:create
			)

			socket = socket
				|> assign(:error, nil)
				|> assign(:list, list)
				|> assign(:form, form)
				|> assign(:page_title, list.title)

			{:ok, socket}
		else
			{:ok, push_redirect(socket, to: "/")}
		end
  end

	def handle_event("save", %{"form" => form}, socket) do
		Todoish.Entries.Item
		|> AshPhoenix.Form.for_create(:new,
			api: Todoish.Entries,
			prepare_params: fn params, _ ->
				Map.put(params, "list_id", socket.assigns.list.id)
			end
		)
		|> AshPhoenix.Form.validate(form)
		|> AshPhoenix.Form.submit()
		|> case do
			{:ok, item} ->
				items = socket.assigns.list.items

				list = %{ socket.assigns.list | items: [item | items]}

				{:noreply, assign(socket, :list ,list)}

			{:error, form} ->
				socket = socket
					|> assign(form: form)
					|> assign(error: "Make sure to put something todo 👆")

				{:noreply, socket}
		end
	end

	def handle_event("validate", _form, socket) do
		if socket.assigns.error != nil do
			{:noreply, assign(socket, :error, nil)}
		else
			{:noreply, socket}
		end
	end

	def handle_event("done", %{"id" => id}, socket) do
		list = socket.assigns.list

		item = Enum.find(list.items, &(&1.id == id))

		if item != nil do
			item =
				if item.status == :completed do
					Ash.Changeset.for_update(item, :incomplete) |> Todoish.Entries.update!()
				else
					Ash.Changeset.for_update(item, :complete) |> Todoish.Entries.update!()
				end

			item_index = Enum.find_index(list.items, &(&1.id == id))

			items = List.replace_at(list.items, item_index, item)

			list = %{list | items: items}

			{:noreply, assign(socket, :list, list)}
		else
			{:noreply, socket}
		end
	end

	def handle_event("delete", %{"id" => id}, socket) do
		list = socket.assigns.list

		item = Enum.find(list.items, &(&1.id == id))

		if item != nil do
			item
			|> Ash.Changeset.for_destroy(:destroy)
			|> Todoish.Entries.destroy!()

			items = List.delete(list.items, item)

			list = %{list | items: items}

			{:noreply, assign(socket, :list, list)}
		end
	end

	def handle_event("share", _value, socket) do
		{:noreply, push_event(socket, "share", %{})}
	end

	def handle_info(%{event: "item-added", payload: payload}, socket) do
		new_item = payload.payload.data

		items = socket.assigns.list.items

		item_in_list = Enum.find(items, &(&1.id == new_item.id))

		if (item_in_list) do
			{:noreply, socket}
		else
			items = [new_item | items]
			list = %{socket.assigns.list | items: items}

			{:noreply, assign(socket, :list, list)}
		end
	end

	def handle_info(%{event: "item-updated", payload: payload}, socket) do
		updated_item = payload.payload.data

		items = socket.assigns.list.items

		item_index = Enum.find_index(items, &(&1.id == updated_item.id))

		if item_index != nil do
			items = List.replace_at(items, item_index, updated_item)
			list = %{socket.assigns.list | items: items}

			{:noreply, assign(socket, :list, list)}
		else
			{:noreply, socket}
		end
	end

	def handle_info(%{event: "item-deleted", payload: payload}, socket) do
		deleted_item = payload.payload.data

		items = socket.assigns.list.items

		item = Enum.find(items, &(&1.id == deleted_item.id))

		if item != nil do
			items = List.delete(items, item)
			list = %{socket.assigns.list | items: items}

			{:noreply, assign(socket, :list, list)}
		else
			{:noreply, socket}
		end
	end
end
