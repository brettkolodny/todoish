defmodule TodoishWeb.PageController do
  use TodoishWeb, :controller

  require Ash.Query

  defp create_new_list(title) do
    url_id = Nanoid.generate()

    lists = Todoish.Entries.List
      |> Ash.Query.filter(url_id == ^url_id)
      |> Ash.Query.limit(1)
      |> Ash.Query.select([])
      |> Todoish.Entries.read_one!()

    if (lists != nil) do
      # On the off chance the id exists, try again
      create_new_list(title)
    else
      Todoish.Entries.List
      |> Ash.Changeset.for_create(:new, %{title: title, url_id: url_id})
      |> Todoish.Entries.create!()

      url_id
    end
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, %{"new_list" => %{"title" => title}}) do
    url_id = create_new_list(title) |> IO.inspect()

    redirect(conn, to: "/#{url_id}")
  end
end
