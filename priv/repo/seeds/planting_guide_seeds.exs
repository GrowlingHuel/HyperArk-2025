alias GreenManTavern.Repo
alias GreenManTavern.PlantingGuide.{PlantFamily, Plant, PlantingWindow, Companion}

defmodule PGSeed.Helper do
  @data_dir Path.join([:code.priv_dir(:green_man_tavern), "data", "planting_guide"]) |> to_string()

  def read_json(file, default \\ []) do
    path = Path.join(@data_dir, file)
    case File.read(path) do
      {:ok, bin} -> Jason.decode!(bin)
      _ -> default
    end
  rescue
    _ -> default
  end

  def ensure_family(%{"name" => name} = attrs) do
    case Repo.get_by(PlantFamily, name: name) do
      nil ->
        %PlantFamily{}
        |> PlantFamily.changeset(%{name: name, description: Map.get(attrs, "description")})
        |> Repo.insert!()
      fam -> fam
    end
  end

  def ensure_plant(%{"name" => name} = attrs, fam_id) do
    case Repo.get_by(Plant, name: name) do
      nil ->
        cz =
          attrs
          |> Map.get("climate_zones")
          |> case do
            nil ->
              # fallback: map single "climate" string to array
              Map.get(attrs, "climate") |> case do
                nil -> []
                s when is_binary(s) -> [s]
                other -> List.wrap(other)
              end
            list -> List.wrap(list)
          end

        %Plant{}
        |> Plant.changeset(%{
          name: name,
          family_id: fam_id,
          climate_zones: cz,
          description: Map.get(attrs, "description")
        })
        |> Repo.insert!()
      plant -> plant
    end
  end

  def ensure_window(%{"plant_id" => plant_id, "month" => m, "hemisphere" => h} = w) do
    act = Map.get(w, "action") || "Plant"
    existing =
      Repo.get_by(PlantingWindow,
        plant_id: plant_id,
        month: m,
        hemisphere: h,
        action: act
      )

    case existing do
      nil ->
        %PlantingWindow{}
        |> PlantingWindow.changeset(%{plant_id: plant_id, month: m, hemisphere: h, action: act})
        |> Repo.insert!()
      win -> win
    end
  end

  def ensure_companion(%{"plant_id" => pid} = c) do
    rel = Map.get(c, "relation") || "good"
    cid = Map.get(c, "companion_plant_id") || Map.get(c, "companion_id")
    notes = Map.get(c, "notes")

    existing =
      Repo.get_by(Companion,
        plant_id: pid,
        companion_plant_id: cid,
        relation: rel
      )

    case existing do
      nil ->
        %Companion{}
        |> Companion.changeset(%{plant_id: pid, companion_plant_id: cid, relation: rel, notes: notes})
        |> Repo.insert!()
      comp -> comp
    end
  end
end

IO.puts("==> Seeding Planting Guide from JSON (idempotent)")

families_json = PGSeed.Helper.read_json("families.json")
plants_json = PGSeed.Helper.read_json("plants.json")
windows_json = PGSeed.Helper.read_json("planting_windows.json")
companions_json = PGSeed.Helper.read_json("companions.json")

{:ok, _} = Repo.transaction(fn ->
  # 1) Families
  families = Enum.map(families_json, &PGSeed.Helper.ensure_family/1)
  fam_by_input_id =
    families_json
    |> Enum.zip(families)
    |> Enum.into(%{}, fn {%{"id" => iid}, fam} -> {iid, fam.id} end)

  IO.puts("Seeded/ensured #{length(families)} families")

  # 2) Plants
  plants =
    Enum.map(plants_json, fn pj ->
      fam_id = Map.get(pj, "family_id") |> case do
        nil -> nil
        id -> Map.get(fam_by_input_id, id, id)
      end
      PGSeed.Helper.ensure_plant(pj, fam_id)
    end)

  plant_by_input_id =
    plants_json
    |> Enum.zip(plants)
    |> Enum.into(%{}, fn {%{"id" => iid}, p} -> {iid, p.id} end)

  IO.puts("Seeded/ensured #{length(plants)} plants")

  # 3) Planting windows
  wins_count =
    windows_json
    |> Enum.map(fn wj ->
      pid = Map.get(wj, "plant_id") |> then(&Map.get(plant_by_input_id, &1, &1))
      wj = Map.put(wj, "plant_id", pid)
      PGSeed.Helper.ensure_window(wj)
    end)
    |> length()

  IO.puts("Seeded/ensured #{wins_count} planting windows")

  # 4) Companions
  comps_count =
    companions_json
    |> Enum.map(fn cj ->
      pid = Map.get(cj, "plant_id") |> then(&Map.get(plant_by_input_id, &1, &1))
      cid = Map.get(cj, "companion_plant_id") || Map.get(cj, "companion_id")
      cid = Map.get(plant_by_input_id, cid, cid)
      cj = cj |> Map.put("plant_id", pid) |> Map.put("companion_plant_id", cid)
      PGSeed.Helper.ensure_companion(cj)
    end)
    |> length()

  IO.puts("Seeded/ensured #{comps_count} companion relationships")
end)

IO.puts("==> Planting Guide seed complete")
