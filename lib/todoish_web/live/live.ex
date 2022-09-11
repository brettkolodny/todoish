defmodule TodoishWeb.Live do
  use Phoenix.LiveView
  use Phoenix.HTML

  require Ash.Query

  def render(assigns) do
    ~H"""
    <%= if @url_id do %>
      <.live_component module={TodoishWeb.Live.List} id="list" platform={@platform} url_id={@url_id} list={@list} />
    <% else %>
      <.live_component module={TodoishWeb.Live.Home} id="home" platform={@platform} />
    <% end %>
    """
  end

  def mount(params, session, socket) do
    IO.inspect(session)
    url_id = params["url_id"]

    socket =
      socket
      |> load_list(url_id)
      |> assign(:error, nil)
      |> assign(:url_id, url_id)

    {:ok, socket}
  end

  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  def handle_event("new-ios", params, socket) do
    case create_list_from_form(params) do
      {:ok, result} ->
        list = %{result | items: []}

        socket =
          socket
          |> assign(:url_id, list.url_id)
          |> assign(:list, list)

        {:noreply, push_patch(socket, to: "/#{list.url_id}")}

      {:error, _form} ->
        # TODO error flash
        {:noreply, socket}
    end
  end

  def handle_event("new", %{"form" => form}, socket) do
    case create_list_from_form(form) do
      {:ok, result} ->
        list = %{result | items: []}

        socket =
          socket
          |> assign(:url_id, list.url_id)
          |> assign(:list, list)

        {:noreply, push_patch(socket, to: "/#{list.url_id}")}

      {:error, _form} ->
        # TODO error flash
        {:noreply, socket}
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

        list = %{socket.assigns.list | items: [item | items]}

        {:noreply, assign(socket, :list, list)}

      {:error, form} ->
        socket =
          socket
          |> assign(form: form)
          |> assign(error: "Make sure to put something todo 👆")

        {:noreply, socket}
    end
  end

  def handle_event("save-ios", form, socket) do
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
        IO.inspect(item)
        items = socket.assigns.list.items

        list = %{socket.assigns.list | items: [item | items]}

        {:noreply, assign(socket, :list, list)}

      {:error, form} ->
        IO.puts("Error in save-ios")

        socket =
          socket
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

  def handle_info({:set_url_id, url_id}, socket) do
    socket = load_list(socket, url_id)
    {:noreply, assign(socket, :url_id, url_id)}
  end

  def handle_info(%{event: "item-added", payload: payload}, socket) do
    IO.puts("new!")
    new_item = payload.payload.data

    items = socket.assigns.list.items

    item_in_list = Enum.find(items, &(&1.id == new_item.id))

    if item_in_list do
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

  defp create_list_from_form(form) do
    Todoish.Entries.List
    |> AshPhoenix.Form.for_create(:create,
      api: Todoish.Entries,
      transform_params: fn params, _ ->
        params =
          if params["title"] in ["", nil] do
            Map.put(params, "title", "A Todoish List")
          else
            params
          end

        params =
          if params["description"] in ["", nil] do
            Map.put(params, "description", "Add items to get started!")
          else
            params
          end

        Map.put(params, "url_id", Nanoid.generate())
      end
    )
    |> AshPhoenix.Form.validate(form)
    |> AshPhoenix.Form.submit()
  end

  defp load_list(socket, url_id) do
    list =
      Todoish.Entries.List
      |> Ash.Query.filter(url_id == ^url_id)
      |> Ash.Query.limit(1)
      |> Ash.Query.select([:title, :id, :url_id, :description])
      |> Ash.Query.load(items: Ash.Query.sort(Todoish.Entries.Item, inserted_at: :desc))
      |> Todoish.Entries.read_one!()

    if list != nil do
      TodoishWeb.Endpoint.subscribe("item:list:#{list.id}")

      form =
        AshPhoenix.Form.for_create(
          Todoish.Entries.Item,
          :create
        )

      socket =
        socket
        |> assign(:error, nil)
        |> assign(:list, list)
        |> assign(:form, form)
        |> assign(:page_title, list.title)
        |> assign(:platform, socket.assigns.platform)

      socket
    else
      socket
    end
  end
end
