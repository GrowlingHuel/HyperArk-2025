defmodule GreenManTavern.PlantingGuide.JsonData do
  @moduledoc """
  Minimal JSON-backed data source for the Planting Guide.

  JSON files live under priv/data/planting_guide/*.json
  and are intentionally small for the MVP.
  """

  @data_dir Path.join([:code.priv_dir(:green_man_tavern), "data", "planting_guide"]) |> to_string()

  def load_families, do: load_json("families.json")
  def load_plants, do: load_json("plants.json")
  def load_windows, do: load_json("planting_windows.json")
  def load_companions, do: load_json("companions.json")

  def filter_plants(filters) do
    families = load_families()
    plants = load_plants()
    windows = load_windows()
    companions = load_companions()

    month = Map.get(filters, :month)
    hemisphere = Map.get(filters, :hemisphere, "N")
    climate = Map.get(filters, :climate, "all")
    family = Map.get(filters, :family, "all")

    family_by_id = Map.new(families, fn f -> {f["id"], f} end)

    plant_windows = Enum.group_by(windows, & &1["plant_id"])
    plant_companions = Enum.group_by(companions, & &1["plant_id"])

    plants
    |> Enum.filter(fn p ->
      ok_family = family == "all" or to_string(p["family_id"]) == to_string(family)
      ok_climate = climate == "all" or String.downcase(to_string(p["climate"])) == String.downcase(to_string(climate))

      ok_month =
        case {month, Map.get(plant_windows, p["id"]) || []} do
          {nil, _} -> true
          {m, wins} -> Enum.any?(wins, fn w -> w["month"] == m and (w["hemisphere"] || "N") == hemisphere end)
        end

      ok_family and ok_climate and ok_month
    end)
    |> Enum.map(fn p ->
      fam = Map.get(family_by_id, p["family_id"]) || %{}
      %{
        id: p["id"],
        name: p["name"],
        family: fam["name"],
        climate: p["climate"],
        windows: Map.get(plant_windows, p["id"]) || [],
        companions: Map.get(plant_companions, p["id"]) || []
      }
    end)
  end

  defp load_json(file, default \\ []) do
    path = Path.join(@data_dir, file)
    case File.read(path) do
      {:ok, content} -> Jason.decode!(content)
      _ -> default
    end
  rescue
    _ -> default
  end
end
