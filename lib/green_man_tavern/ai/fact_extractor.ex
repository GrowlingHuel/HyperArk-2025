defmodule GreenManTavern.AI.FactExtractor do
  @moduledoc """
  Extracts compact, factual user details from freeform messages and merges them
  into persistent user profile memories.

  Facts schema (stored in user.profile_data["facts"]):
  %{
    "type" => string,
    "key" => string,
    "value" => string,
    "confidence" => float,
    "source" => string,
    "learned_at" => ISO8601 timestamp,
    "context" => optional string
  }
  """

  require Logger
  alias GreenManTavern.AI.ClaudeClient

  @extraction_instructions ~S"""
  Extract ALL factual information from the user message that should be remembered.
  Be AGGRESSIVE: extract multiple facts from compound phrases.
  Do not include opinions or open-ended questions, but include implied facts.

  Confidence scale:
  - 0.60–0.70 = implied or partially certain (user hinted)
  - 0.80–0.90 = stated clearly
  - 1.00 = emphasized or repeated

  Respond ONLY with a JSON array of facts. Each fact has:
  - type: category (location/planting/climate/resource/constraint/goal/sunlight/water/soil/etc)
  - key: specific aspect (e.g., "city", "plant_type", "container_type", "container_material")
  - value: the extracted value (string)
  - confidence: 0.0–1.0
  - context: (optional) detail if needed

  Extract MULTIPLE facts from single sentences. Examples:
  - "I live in Melbourne" → [{"type":"location","key":"city","value":"Melbourne","confidence":0.95}]
  - "It's a boxed patch in my backyard, gets morning sun" → [
      {"type":"planting","key":"container_type","value":"boxed patch of earth","confidence":0.90},
      {"type":"planting","key":"location","value":"backyard","confidence":0.90},
      {"type":"sunlight","key":"timing","value":"morning","confidence":0.95}
    ]
  - "I'm planting basil in a wooden box on my balcony in Melbourne" → [
      {"type":"planting","key":"plant_type","value":"basil","confidence":1.0},
      {"type":"planting","key":"container_type","value":"wooden box","confidence":0.90},
      {"type":"planting","key":"container_material","value":"wood","confidence":0.80},
      {"type":"location","key":"area","value":"balcony","confidence":0.90},
      {"type":"location","key":"city","value":"Melbourne","confidence":0.95},
      {"type":"planting","key":"planting_status","value":"planning to plant","confidence":0.85}
    ]

  If no concrete facts to extract, return empty array: []
  """

  @doc """
  Extracts facts from user_message using Claude, returns list of maps.
  """
  def extract_facts(user_message, character_name) when is_binary(user_message) do
    system_prompt = ~s(You are a fact extractor. Output ONLY JSON array of facts per the instructions.)
    prompt = """
    #{@extraction_instructions}

    User said: "#{user_message}"
    """

    case ClaudeClient.chat(prompt, system_prompt) do
      {:ok, json_text} ->
        Logger.info("[Facts] Raw response: #{String.slice(inspect(json_text), 0, 400)}...")
        parsed = parse_facts_json(json_text, character_name)
        total = length(parsed)
        # Enforce minimum confidence 0.6
        {kept, filtered} = Enum.split_with(parsed, fn f -> (f["confidence"] || 0.0) >= 0.6 end)
        if filtered != [] do
          Logger.info("[Facts] Filtered #{length(filtered)} low-confidence facts (<0.6)")
        end
        Logger.info("[Facts] Parsed=#{total}, Kept=#{length(kept)}")
        kept

      {:error, reason} ->
        Logger.warn("Fact extraction failed: #{inspect(reason)}")
        []
    end
  rescue
    error ->
      Logger.warn("Fact extraction exception: #{inspect(error)}")
      []
  end

  defp parse_facts_json(json_text, character_name) do
    learned_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    with {:ok, data} <- Jason.decode(json_text) do
      facts =
        data
        |> List.wrap()
        |> Enum.filter(&is_map/1)
        |> Enum.map(fn fact ->
          %{
            "type" => Map.get(fact, "type", "unknown"),
            "key" => Map.get(fact, "key", "unknown"),
            "value" => to_string(Map.get(fact, "value", "")),
            "confidence" => fact |> Map.get("confidence", 0.0) |> to_float_safe(),
            "source" => character_name,
            "learned_at" => learned_at,
            "context" => Map.get(fact, "context")
          }
        end)

      Enum.filter(facts, fn f -> String.trim(f["value"]) != "" end)
    else
      _ ->
        # Try to salvage JSON if wrapped or with extra text
        case extract_json_array(json_text) do
          {:ok, arr} -> parse_facts_json(arr, character_name)
          _ -> []
        end
    end
  end

  defp to_float_safe(v) when is_float(v), do: v
  defp to_float_safe(v) when is_integer(v), do: v / 1.0
  defp to_float_safe(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> f
      _ -> 0.0
    end
  end
  defp to_float_safe(_), do: 0.0

  defp extract_json_array(text) do
    case Regex.run(~r/\[(.|\n|\r)*\]/, text) do
      [json] -> {:ok, json}
      _ -> :error
    end
  end

  @doc """
  Merge by appending and removing duplicates based on {type,key,value}.
  Sort by learned_at desc.
  """
  def merge_facts(existing_facts, new_facts) do
    all = List.wrap(existing_facts) ++ List.wrap(new_facts)
    all
    |> Enum.uniq_by(fn f -> {Map.get(f, "type"), Map.get(f, "key"), Map.get(f, "value")} end)
    |> Enum.sort_by(fn f -> Map.get(f, "learned_at", "") end, :desc)
  end
end
