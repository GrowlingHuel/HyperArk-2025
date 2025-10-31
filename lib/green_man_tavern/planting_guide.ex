defmodule GreenManTavern.PlantingGuide do
  @moduledoc """
  Context for Planting Guide data (families, plants, windows, companions).
  """

  import Ecto.Query
  alias GreenManTavern.Repo
  alias GreenManTavern.PlantingGuide.{PlantFamily, Plant, PlantingWindow, Companion}

  @doc """
  List all plant families.
  """
  def list_families do
    Repo.all(from f in PlantFamily, order_by: [asc: f.name])
  end

  @doc """
  List plants with optional filters:
  - family_id: integer or binary id
  - climate_zones: string or list of strings; matches any in plant.climate_zones
  Preloads family, planting_windows, companions (with companion_plant).
  """
  def list_plants(filters \\ %{}) do
    family_id = normalize_id(Map.get(filters, :family_id) || Map.get(filters, "family_id"))
    cz = Map.get(filters, :climate_zones) || Map.get(filters, "climate_zones")
    cz_list = normalize_list(cz)

    base = from p in Plant
    q =
      base
      |> maybe_filter_family(family_id)
      |> maybe_filter_climate(cz_list)

    q
    |> order_by([p], asc: p.name)
    |> preload([:family, :planting_windows, companions: [:companion_plant]])
    |> Repo.all()
  end

  defp maybe_filter_family(q, nil), do: q
  defp maybe_filter_family(q, family_id), do: (from p in q, where: p.family_id == ^family_id)

  defp maybe_filter_climate(q, []), do: q
  defp maybe_filter_climate(q, zones), do: (from p in q, where: fragment("? && ?", p.climate_zones, ^zones))

  @doc """
  Get planting windows for a plant/month/hemisphere.
  """
  def get_planting_windows(plant_id, month, hemisphere) do
    Repo.all(
      from w in PlantingWindow,
        where: w.plant_id == ^plant_id and w.month == ^month and w.hemisphere == ^hemisphere,
        order_by: [asc: w.action]
    )
  end

  @doc """
  Get companion plants for a plant.
  relation: "good" | "bad" | nil (all)
  Returns list of Plant structs.
  """
  def get_companions(plant_id, relation \\ nil) do
    q =
      from c in Companion,
        where: c.plant_id == ^plant_id,
        preload: [:companion_plant]

    q = if relation, do: from(c in q, where: c.relation == ^relation), else: q

    q
    |> Repo.all()
    |> Enum.map(& &1.companion_plant)
  end

  @doc """
  Filter already-loaded plants by month and hemisphere using their preloaded windows.
  """
  def filter_plants_by_month(plants, month, hemisphere) do
    Enum.filter(plants, fn p ->
      Enum.any?(p.planting_windows || [], fn w -> w.month == month and w.hemisphere == hemisphere end)
    end)
  end

  defp normalize_id(nil), do: nil
  defp normalize_id(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      _ -> val
    end
  end
  defp normalize_id(val), do: val

  defp normalize_list(nil), do: []
  defp normalize_list(val) when is_binary(val), do: [val]
  defp normalize_list(val) when is_list(val), do: val
  defp normalize_list(_), do: []
end
