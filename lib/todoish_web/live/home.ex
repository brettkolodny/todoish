defmodule TodoishWeb.Live.Home do
  use Phoenix.LiveView
  use Phoenix.HTML

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-4">
      <div class="flex flex-col justify-center items-center gap-1 md:gap-2">
        <h1 class="flex flex-row justify-start items-center">
            <div class="font-bold text-3xl md:text-6xl text-base-900">Todoish</div>
            <div class="text-base transform -translate-y-2">✅</div>
        </h1>
        <h2 class="text-base md:text-lg">Share todos, grocery lists, or anything else!</h2>
      </div>
      <div class="flex flex-col justify-center items-center w-full max-w-xs md:max-w-lg bg-white p-6 md:p-16 rounded-lg border border-base-300">
        <.form let={f} for={@form} phx-submit="new" class="flex flex-col gap-4 w-full">
          <%= text_input f, :title, [placeholder: "My awesome list!", class: ["w-full h-12 rounded-md bg-base-100"]] %>
          <%= textarea f, :description, [placeholder: "My awesome list's description!", class: ["w-full h-24 rounded-md bg-base-100 mb-4"]] %>
          <!-- TODO error flash -->
          <%= submit "Create a Todoish!", [class: ["bg-primary-400 text-white h-12 text-lg rounded-md hover:bg-primary-500 transition-colors"]] %>
        </.form>
      </div>
    </div>
    """
  end

  def mount(_params, _sessions, socket) do
    form = AshPhoenix.Form.for_create(Todoish.Entries.List, :create)

    {:ok, assign(socket, :form, form)}
  end

  def handle_event("new", %{"form" => form}, socket) do
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
    |> case do
      {:ok, result} ->
        IO.inspect(result)
        {:noreply, redirect(socket, to: "/#{result.url_id}")}

      {:error, _form} ->
        # TODO error flash
        {:noreply, socket}
    end
  end
end
