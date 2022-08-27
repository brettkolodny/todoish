defmodule TodoishWeb.Live.List do
  use Phoenix.LiveView
	use Phoenix.HTML

  require Ash.Query

  def render(assigns) do
		~L"""
		<div class="flex flex-col justify-center items-center gap-8 w-screen">
			<h1 class="flex flex-row justify-start items-center">
					<div class="font-bold text-6xl text-base-900"><%= @list.title %></div>
					<div class="text-2xl transform -translate-y-2">✅</div>
			</h1>
			<div class="flex flex-col justify-center items-center gap-4 w-full max-w-lg bg-white px-16 pt-16 pb-8 rounded-lg border border-base-300">
				<%= for item <- Enum.sort(@list.items, &(&1.inserted_at > &2.inserted_at)) do %>
					<div class="flex flex-row justify-center items-center gap-2 w-full #{item.status == :closed, do: "opacity-50"}">
						<div class="flex justify-start items-center w-full h-12 pl-4 rounded-md bg-base-50 border border-base-200">
							<%= item.title %>
						</div>
						<div class="text-xl cursor-pointer">✅</div>
					</div>
				<% end %>
				<%= f = form_for @form, "#", [phx_submit: :save, class: "flex flex-row w-full gap-2 mb-8"] %>
					<%= text_input f, :title, [id: "new-todo", placeholder: "More pizza!", class: ["w-full h-12 rounded-md bg-base-100"]] %>
					<%= submit "➕", [class: ["text-xl"]] %>
				</form>
				<div class="flex justify-center items-center w-full bg-primary-400 text-white h-12 text-lg rounded-md hover:bg-primary-500 transition-colors cursor-pointer">Share this list!</div>
			</div>
		</div>
		"""
  end

  def mount(%{"url_id" => url_id}, _sessions, socket) do
		list = Todoish.Entries.List
	  	|> Ash.Query.filter(url_id == ^url_id)
	  	|> Ash.Query.limit(1)
	  	|> Ash.Query.select([:title, :items, :id, :url_id])
			|> Ash.Query.load([:items])
	  	|> Todoish.Entries.read_one!()

		if list == nil do
			{:ok, push_redirect(socket, to: "/")}
		else
			TodoishWeb.Endpoint.subscribe("item:list:#{list.id}")

			form = AshPhoenix.Form.for_create(
				Todoish.Entries.Item,
				:create
			)

			socket = socket
				|> assign(:list, list)
				|> assign(:form, form)

			{:ok, socket}
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

	def handle_info(%{event: "item-added"}, socket) do
		list = Todoish.Entries.List
		|> Ash.Query.filter(url_id == ^socket.assigns.list.url_id)
		|> Ash.Query.limit(1)
		|> Ash.Query.select([:title, :items, :id, :url_id])
		|> Ash.Query.load([:items])
		|> Todoish.Entries.read_one!()

		{:noreply, assign(socket, :list, list)}
	end
end
