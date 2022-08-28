defmodule TodoishWeb.Live.List do
  use Phoenix.LiveView
	use Phoenix.HTML

  require Ash.Query

  def render(assigns) do
		~L"""
		<div class="flex flex-col justify-center items-center gap-8 w-screen">
			<div class="flex flex-col justify-center items-center gap-1 md:gap-2">
				<h1 class="flex flex-row justify-start items-center">
						<div class="font-bold text-3xl md:text-6xl text-base-900"><%= @list.title %></div>
						<div class="text-base md:text-2xl transform -translate-y-2">✅</div>
				</h1>
				<h2 class="text-lg">
					<%= @list.description %>
				</h2>
			</div>
			<div class="flex flex-col justify-center items-center gap-4 w-full max-w-xs md:max-w-lg bg-white px-6 md:px-16 pt-6 md:pt-16 pb-3 md:pb-8 rounded-lg border border-base-300">
				<%= for item <- Enum.reverse(@list.items) do %>
					<div class="flex flex-row justify-center items-center gap-2 w-full">
						<div class="flex justify-start items-center w-full h-12 pl-4 rounded-md bg-base-50 border border-base-200 <%= if item.status == :completed, do: "opacity-30"%>">
							<%= item.title %>
						</div>
						<div class="text-xl cursor-pointer" phx-click="done" phx-value-id="<%= item.id %>">
							<%= if item.status == :incompleted do %>
								✅
							<% else %>
								🔁
							<% end %>
						</div>
					</div>
				<% end %>
				<%= f = form_for @form, "#", [phx_submit: :save, class: "flex flex-row w-full gap-2 mb-8"] %>
					<%= text_input f, :title, [id: "new-todo", placeholder: "More pizza!", class: ["w-full h-12 rounded-md bg-base-100"]] %>
					<%= submit "➕", [class: ["text-xl"]] %>
				</form>
				<div phx-click="share" id="share-button" class="flex justify-center items-center w-full bg-primary-400 text-white h-12 text-lg rounded-md hover:bg-primary-500 transition-colors cursor-pointer">Share this list!</div>
			</div>
		</div>
		"""
  end

  def mount(%{"url_id" => url_id}, _sessions, socket) do
		list = Todoish.Entries.List
	  	|> Ash.Query.filter(url_id == ^url_id)
	  	|> Ash.Query.limit(1)
	  	|> Ash.Query.select([:title, :items, :id, :url_id, :description])
			|> Ash.Query.load([:items])
	  	|> Todoish.Entries.read_one!()

		if list != nil do
			TodoishWeb.Endpoint.subscribe("item:list:#{list.id}")

			form = AshPhoenix.Form.for_create(
				Todoish.Entries.Item,
				:create
			)

			socket = socket
				|> assign(:list, list)
				|> assign(:form, form)
				|> assign(:page_title, list.title)

			{:ok, socket}
		else
			{:ok, push_redirect(socket, to: "/")}
		end
  end

	def handle_event("save", %{"form" => %{"title" => title}}, socket) do
		list = socket.assigns.list

		item = Todoish.Entries.Item
			|> Ash.Changeset.for_create(:new, %{title: title})
			|> Todoish.Entries.create!()
			|> Ash.Changeset.for_update(:add, %{list_id: list.id})
			|> Todoish.Entries.update!()

		list = %{ list | items: [item | list.items]}

		socket = socket
			|> assign(:list, list)
			|> push_event("clear", %{})

		{:noreply, socket}
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

	def handle_event("share", _value, socket) do
		IO.puts("share!")

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
end
