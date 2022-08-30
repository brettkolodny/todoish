defmodule TodoishWeb.PageController do
  use TodoishWeb, :controller

  require Ash.Query

  defp create_new_list(title, description) do
    title = if title != "" do title else "A Todoish list" end
    description = if description != "" do description else "Add items to get started!" end

    url_id = Nanoid.generate()

    Todoish.Entries.List
    |> Ash.Changeset.for_create(:new, %{title: title, url_id: url_id, description: description})
    |> Todoish.Entries.create!()

    url_id
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, %{"new_list" => %{"title" => title, "description" => description}}) do
    url_id = create_new_list(title, description)

    redirect(conn, to: "/#{url_id}")
  end
end
