defmodule GreenManTavern.Repo do
  use Ecto.Repo,
    otp_app: :green_man_tavern,
    adapter: Ecto.Adapters.Postgres
end
