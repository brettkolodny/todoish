defmodule Todoish.Repo do
  use AshPostgres.Repo, otp_app: :todoish

  def installed_extensions do
    ["uuid-ossp", "citext"]
  end
end
