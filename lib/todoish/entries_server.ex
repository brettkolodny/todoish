defmodule Todoish.EntriesServer do
  use GenServer

  require Ash.Query

  # 7 days
  @keep_alive 604_800_000

  def start_link(_state) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(_state) do
    TodoishWeb.Endpoint.subscribe("list:created")

    lists =
      Todoish.Entries.List
      |> Ash.Query.select([:id, :inserted_at])
      |> Todoish.Entries.read!()

    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    for list <- lists do
      inserted_at = DateTime.to_unix(list.inserted_at, :millisecond)
      delete_at = inserted_at + @keep_alive

      if now > delete_at do
        spawn(fn -> delete_list_and_items(list) end)
      else
        spawn(fn -> delete_list_and_items(list, delete_at - now) end)
      end
    end

    {:ok, %{}}
  end

  @impl true
  def handle_info(%{event: "new-list", payload: payload}, state) do
    spawn(fn -> delete_list_and_items(payload.data, @keep_alive) end)

    {:noreply, state}
  end

  defp delete_list_and_items(list, delay \\ 0) do
    # :pass
    :timer.sleep(delay)

    list =
      Todoish.Entries.List
      |> Ash.Query.filter(id == ^list.id)
      |> Ash.Query.limit(1)
      |> Ash.Query.select([])
      |> Ash.Query.load(items: Ash.Query.select(Todoish.Entries.Item, [:id]))
      |> Todoish.Entries.read_one!()

    # user_lists =
    #  Todoish.Entries.List
    #  |> Ash.Query.filter(list_id == ^list.id)
    #  |> Ash.Query.select([])
    #  |> Todoish.Entries.read!()

    for item <- list.items do
      item
      |> Ash.Changeset.for_destroy(:destroy)
      |> Todoish.Entries.destroy!()
    end

    list
    |> Ash.Changeset.for_destroy(:destroy)
    |> Todoish.Entries.destroy!()
  end
end
