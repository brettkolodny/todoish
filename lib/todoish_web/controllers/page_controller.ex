defmodule TodoishWeb.PageController do
  use TodoishWeb, :controller

  require Ash.Query

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, %{"new_list" => params}) do
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
    |> AshPhoenix.Form.validate(params)
    |> AshPhoenix.Form.submit()
    |> case do
      {:ok, result} ->
        if conn.assigns.current_user do
          user = conn.assigns.current_user

          Todoish.Entries.UsersLists
          |> Ash.Changeset.for_create(:new, %{list_id: result.id, user_id: user.id})
          |> Todoish.Entries.create!()
        end

        redirect(conn, to: "/#{result.url_id}")

      {:error, form} ->
        IO.inspect(form)

        conn
        |> put_flash(:error, "Uh-oh! Something went wrong. Please try again!")
        |> render("index.html", form: form)
    end
  end
end
