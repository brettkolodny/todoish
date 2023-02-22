defmodule TodoishWeb.ProfileController do
  use TodoishWeb, :controller

  require Ash.Query

  def profile(conn, _params) do
    if conn.assigns.current_user do
      user = conn.assigns.current_user

      user =
        Todoish.Entries.User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.limit(1)
        |> Ash.Query.load(:lists)
        |> Todoish.Entries.read_one!()

      conn
      |> assign(:lists, user.lists)
      |> render("profile.html")
    else
      conn
      |> put_session(:return_to, "/profile")
      |> redirect(to: "/sign-in")
    end
  end

  def remove_list(conn, %{"list_id" => list_id}) do
    if conn.assigns.current_user do
      user = conn.assigns.current_user

      Todoish.Entries.UsersLists
      |> Ash.Query.filter(user_id == ^user.id and list_id == ^list_id)
      |> Ash.Query.limit(1)
      |> Todoish.Entries.read_one!()
      |> Ash.Changeset.for_destroy(:destroy)
      |> Todoish.Entries.destroy!()

      redirect(conn, to: "/profile")
    else
      conn
      |> put_session(:return_to, "/profile")
      |> redirect(to: "/sign-in")
    end
  end
end
