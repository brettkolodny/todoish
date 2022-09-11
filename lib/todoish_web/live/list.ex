defmodule TodoishWeb.Live.List do
  use Phoenix.LiveComponent
  use Phoenix.HTML

  require Ash.Query

  def render(%{platform: :ios} = assigns) do
    ~H"""
    <app-body>
      <hstack alignment="center">
        <text font="largetitle" font-weight="black" color="#1F2933"><%= @list.title %></text>
        <vstack alignment="leading">
          <text font="footnote">✅</text>
          <text font="footnote"><%= " " %></text>
        </vstack>
      </hstack>
      <text font="subheadline" color="#1F2933"><%= @list.description %></text>
      <list-panel>
        <%= for item <- Enum.reverse(@list.items) do %>
          <hstack id={item.id}>
            <button phx-click="done" phx-value-id={item.id}>
              <text>
                <%= if item.status == :incompleted do %>
                  ✅
                <% else %>
                  🔁
                <% end %>
              </text>
            </button>
            <list-item title={item.title} status={Atom.to_string(item.status)} />
            <button phx-click="delete" phx-value-id={item.id}>
              <text>🗑️</text>
            </button>
          </hstack>
        <% end %>
        <phx-form id="form" phx-submit="save-ios">
          <hstack>
            <phx-submit-button after-submit="clear"><text>➕</text></phx-submit-button>
            <textfield placeholder="Add something!" name="title"></textfield>
            <text>➕</text>
          </hstack>
        </phx-form>
        <share-button url={"https://www.todoi.sh/#{@list.url_id}"} />
      </list-panel>
      <spacer />
    </app-body>
    """
  end

  def render(%{platform: :web} = assigns) do
    ~H"""
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
    				<div class="w-6 text-xl text-center cursor-pointer" phx-click="done" phx-value-id={item.id}>
    					<%= if item.status == :incompleted do %>
    						✅
    					<% else %>
    						🔁
    					<% end %>
    				</div>
    				<div class={"flex justify-start items-center w-56 md:w-96 min-h-min py-3 pl-4 text-sm md:text-base rounded-md-md bg-base-50 border border-base-200 #{if item.status == :completed, do: "opacity-30"}"}>
    					<%= item.title %>
    				</div>
    				<div class="w-6 cursor-pointer text-xl text-center" phx-click="delete" phx-value-id={item.id}>🗑️</div>
    			</div>
    		<% end %>
      <.form let={f} for={@form} phx-change="validate" phx-submit="save" class="flex flex-row justify-center w-full gap-2">
    			<%= submit "➕", [class: ["w-6 text-xl"]] %>
    			<%= text_input f, :title, [id: "new-todo", placeholder: "More pizza!", class: ["w-56 md:w-96 h-12 text-sm md:text-base rounded-md bg-base-100"]] %>
    			<div class="flex justify-center items-center w-6"></div>
    		</.form>
    		<div class="mb-8">
    			<%= if @error != nil do %>
    				<div class="flex flex-row items-center w-56 md:w-96 h-12 px-4 md:px-6 rounded-md bg-red-100 text-sm md:text-base text-red-600"><%= @error %></div>
    			<% end %>
    		</div>
    		<div phx-click="share" id="share-button" class="flex justify-center items-center w-56 md:w-96 bg-primary-400 text-white h-12 text-base md:text-lg rounded-md hover:bg-primary-500 transition-colors cursor-pointer">Share this list!</div>
    	</div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    form =
      AshPhoenix.Form.for_create(
        Todoish.Entries.Item,
        :create
      )

    list = assigns.list

    socket =
      socket
      |> assign(:error, nil)
      |> assign(:form, form)
      |> assign(:list, list)
      |> assign(:page_title, list.title)
      |> assign(:platform, assigns.platform)

    {:ok, socket}
  end
end
