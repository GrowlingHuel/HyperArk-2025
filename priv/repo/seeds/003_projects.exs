alias GreenManTavern.Repo
alias GreenManTavern.Systems.Project

# Clear existing data
Repo.delete_all(Project)

# Food Systems
food_systems = [
  %{
    name: "Herb Garden",
    description: "A compact vertical or container herb garden for culinary use. Perfect for small spaces and beginners.",
    category: "food",
    inputs: %{
      "seeds/plants" => "small quantity",
      "soil" => "20-30L per container",
      "water" => "2-3L per week per plant",
      "sunlight" => "6-8 hours daily",
      "containers" => "optional"
    },
    outputs: %{
      "fresh herbs" => "50-100g per week",
      "dried herbs" => "seasonal",
      "seeds" => "yearly"
    },
    constraints: ["rental_friendly", "low_cost", "small_space"],
    icon_name: "herb_garden",
    skill_level: "beginner"
  },
  %{
    name: "Vegetable Patch",
    description: "Raised bed or in-ground vegetable garden for seasonal produce. Requires regular maintenance and planning.",
    category: "food",
    inputs: %{
      "seeds/seedlings" => "varied",
      "soil" => "50-100L per m2",
      "compost" => "10-20L per m2 seasonally",
      "water" => "10-20L per m2 per week",
      "sunlight" => "6+ hours daily",
      "tools" => "basic gardening"
    },
    outputs: %{
      "vegetables" => "seasonal harvest",
      "green waste" => "composting material",
      "seeds" => "seed saving opportunity"
    },
    constraints: ["space_required"],
    icon_name: "vegetable_patch",
    skill_level: "beginner"
  },
  %{
    name: "Fruit Trees",
    description: "Dwarf or standard fruit trees for long-term food production. Requires patience and proper site selection.",
    category: "food",
    inputs: %{
      "tree" => "1 per location",
      "soil prep" => "deep hole with good drainage",
      "mulch" => "100L per year",
      "water" => "deep watering 1-2x weekly",
      "fertilizer" => "seasonal",
      "pruning time" => "annual"
    },
    outputs: %{
      "fruit" => "seasonal harvest 20-100kg annually",
      "leaves" => "composting material",
      "prunings" => "mulch or compost",
      "shade" => "microclimate benefits"
    },
    constraints: ["climate_specific", "long_term"],
    icon_name: "fruit_trees",
    skill_level: "intermediate"
  },
  %{
    name: "Mushroom Logs",
    description: "Shiitake or oyster mushrooms grown on inoculated logs. Minimal space, high protein yield.",
    category: "food",
    inputs: %{
      "logs" => "hardwood 50-100cm long",
      "spawn" => "inoculation plugs",
      "shade" => "mostly shady location",
      "moisture" => "high humidity",
      "time" => "6-12 months to fruit"
    },
    outputs: %{
      "mushrooms" => "2-5kg per log per season",
      "spent logs" => "composting material",
      "mycelium network" => "soil improvement"
    },
    constraints: ["specific_conditions", "initial_setup"],
    icon_name: "mushroom_logs",
    skill_level: "intermediate"
  },
  %{
    name: "Chicken Coop",
    description: "Small-scale chicken keeping for eggs and pest control. Legal in most urban areas with restrictions.",
    category: "food",
    inputs: %{
      "chickens" => "2-6 birds recommended",
      "coop" => "secure housing",
      "feed" => "500g-1kg per bird weekly",
      "water" => "constant supply",
      "grit" => "calcium supplement",
      "space" => "minimum 1m2 per bird"
    },
    outputs: %{
      "eggs" => "4-6 per week per hen",
      "manure" => "excellent compost material",
      "pest_control" => "natural insect management",
      "soil_turnover" => "as they scratch"
    },
    constraints: ["legal_check_required", "ongoing_care", "noise"],
    icon_name: "chicken_coop",
    skill_level: "advanced"
  },
  %{
    name: "Aquaponics Setup",
    description: "Combined fish and plant growing system. Efficient use of water and nutrients.",
    category: "food",
    inputs: %{
      "fish" => "tropical or coldwater species",
      "tank" => "100-300L capacity",
      "grow_beds" => "media or floating",
      "pump" => "circulation system",
      "pH_monitoring" => "regular testing",
      "electricity" => "continuous pump operation"
    },
    outputs: %{
      "fish_protein" => "seasonal harvest",
      "vegetables" => "year-round production",
      "water" => "nearly closed loop"
    },
    constraints: ["technical_setup", "monitoring_required", "electricity_dependent"],
    icon_name: "aquaponics",
    skill_level: "advanced"
  }
]

# Water Systems
water_systems = [
  %{
    name: "Rainwater Tank",
    description: "Water storage tank for rain collection from roof. Essential for water independence.",
    category: "water",
    inputs: %{
      "tank" => "2000-10000L capacity",
      "guttering" => "roof collection system",
      "filter" => "first flush diverter",
      "pump" => "pressure system",
      "roof_area" => "minimum 50m2 effective"
    },
    outputs: %{
      "water" => "80-90% of roof collection",
      "reduced_bills" => "utility savings"
    },
    constraints: ["legal_requirements", "space_required", "setup_cost"],
    icon_name: "rainwater_tank",
    skill_level: "beginner"
  },
  %{
    name: "Swale System",
    description: "Contour-based water management to slow, spread, and sink water into landscape.",
    category: "water",
    inputs: %{
      "earthworks" => "contour excavation",
      "topography" => "sloping ground needed",
      "design" => "water flow planning",
      "vegetation" => "bank stabilization",
      "time" => "initial earthworks"
    },
    outputs: %{
      "groundwater_recharge" => "improved water table",
      "erosion_control" => "soil retention",
      "microclimate" => "local humidity boost"
    },
    constraints: ["slope_required", "earthworks_permit", "landscaping"],
    icon_name: "swale",
    skill_level: "advanced"
  },
  %{
    name: "Greywater Filter",
    description: "Simple multi-stage filter for reusing household greywater in garden. Reduces water waste.",
    category: "water",
    inputs: %{
      "filter_media" => "gravel, sand, charcoal",
      "settling_tank" => "solids separation",
      "pipes" => "connection to drain",
      "overflow" => "legal discharge point",
      "maintenance" => "monthly"
    },
    outputs: %{
      "filtered_water" => "safe for irrigation",
      "reduced_consumption" => "water conservation"
    },
    constraints: ["plumbing_skills", "legal_compliance", "ongoing_maintenance"],
    icon_name: "greywater_filter",
    skill_level: "intermediate"
  },
  %{
    name: "Pond System",
    description: "Water feature that supports aquatic life and creates microclimate benefits.",
    category: "water",
    inputs: %{
      "excavation" => "1-3m deep",
      "liner" => "EPDM or clay",
      "plants" => "aquatic species",
      "pump" => "optional circulation",
      "fish" => "optional for ecosystem"
    },
    outputs: %{
      "water_storage" => "fire prevention",
      "wildlife_habitat" => "biodiversity",
      "microclimate" => "local cooling",
      "aesthetics" => "landscape value"
    },
    constraints: ["space_required", "maintenance", "safety_considerations"],
    icon_name: "pond",
    skill_level: "intermediate"
  },
  %{
    name: "Keyline Irrigation",
    description: "Precision water distribution system based on natural topography for efficient irrigation.",
    category: "water",
    inputs: %{
      "planning" => "topographic survey",
      "pipes" => "distribution network",
      "emitters" => "drip or spray",
      "timer" => "automated scheduling",
      "pressure_regulator" => "consistent flow"
    },
    outputs: %{
      "water_efficiency" => "40-60% reduction",
      "targeted_delivery" => "plant-specific watering",
      "time_savings" => "automated irrigation"
    },
    constraints: ["technical_design", "installation_cost", "planning_required"],
    icon_name: "keyline_irrigation",
    skill_level: "advanced"
  }
]

# Waste Systems
waste_systems = [
  %{
    name: "Compost Bin",
    description: "Traditional composting system for organic waste. Requires proper carbon/nitrogen balance.",
    category: "waste",
    inputs: %{
      "green_waste" => "kitchen scraps, grass clippings",
      "brown_matter" => "leaves, cardboard, sawdust",
      "water" => "keep moist",
      "air" => "turn regularly",
      "time" => "2-6 months"
    },
    outputs: %{
      "compost" => "100-200L per cycle",
      "reduced_waste" => "60-70% organic diversion"
    },
    constraints: ["space_required", "ongoing_attention", "odor_potential"],
    icon_name: "compost_bin",
    skill_level: "beginner"
  },
  %{
    name: "Worm Farm",
    description: "Vermicomposting system using red wriggler worms. Compact and highly efficient.",
    category: "waste",
    inputs: %{
      "worms" => "500-2000g initial",
      "bedding" => "shredded paper/cardboard",
      "food_scraps" => "500g-2kg weekly",
      "container" => "tiered system",
      "moisture" => "damp not wet"
    },
    outputs: %{
      "worm_castings" => "premium fertilizer",
      "worm_tea" => "liquid fertilizer",
      "reduced_waste" => "biodegradable diversion"
    },
    constraints: ["temperature_sensitive", "careful_feeding", "proper_drainage"],
    icon_name: "worm_farm",
    skill_level: "beginner"
  },
  %{
    name: "Bokashi Bucket",
    description: "Anaerobic fermentation system that can process meat and dairy. Fast and odorless indoors.",
    category: "waste",
    inputs: %{
      "bucket" => "specialized airtight container",
      "bran" => "bokashi inoculant",
      "organic_waste" => "all kitchen scraps",
      "drainage" => "leachate collection",
      "time" => "2-4 weeks"
    },
    outputs: %{
      "pre_compost" => "fermented waste ready for soil",
      "leachate" => "liquid fertilizer",
      "reduced_waste" => "complete bio-waste diversion"
    },
    constraints: ["ongoing_bran_cost", "two_bucket_system", "indoor_storage"],
    icon_name: "bokashi_bucket",
    skill_level: "beginner"
  },
  %{
    name: "Chicken Manure Compost",
    description: "High-nitrogen compost from chicken bedding and manure. Powerful fertilizer.",
    category: "waste",
    inputs: %{
      "manure" => "chicken droppings and bedding",
      "carbon_layer" => "straw, sawdust",
      "curing_time" => "3-6 months",
      "mixing" => "regular turning"
    },
    outputs: %{
      "compost" => "premium high-nutrient",
      "safe_fertilizer" => "properly aged",
      "waste_management" => "manure disposal"
    },
    constraints: ["requires_chickens", "curing_time", "strong_odor_if_mishandled"],
    icon_name: "chicken_manure",
    skill_level: "intermediate"
  },
  %{
    name: "Humanure System",
    description: "Composting toilet system for human waste. Ultimate closed-loop approach.",
    category: "waste",
    inputs: %{
      "toilet_unit" => "composting toilet",
      "sawdust" => "cover material",
      "compost_processing" => "2-year maturation",
      "legal_compliance" => "health codes",
      "education" => "proper use protocol"
    },
    outputs: %{
      "compost" => "humanure after proper aging",
      "water_savings" => "no flush water",
      "nutrient_cycling" => "complete loop"
    },
    constraints: ["legal_compliance", "cultural_considerations", "extended_processing"],
    icon_name: "humanure_system",
    skill_level: "advanced"
  }
]

# Energy Systems
energy_systems = [
  %{
    name: "Solar Panel Array",
    description: "Photovoltaic panels for renewable electricity. Grid-tied or off-grid options.",
    category: "energy",
    inputs: %{
      "panels" => "250-400W each",
      "mounting" => "roof or ground system",
      "inverter" => "DC to AC conversion",
      "batteries" => "optional storage",
      "sunlight" => "peak hours",
      "electrical_install" => "licensed work"
    },
    outputs: %{
      "electricity" => "depends on array size",
      "reduced_bills" => "energy independence",
      "excess_export" => "grid credit"
    },
    constraints: ["significant_investment", "professional_install", "grid_connection"],
    icon_name: "solar_panels",
    skill_level: "advanced"
  },
  %{
    name: "Rocket Stove",
    description: "Highly efficient wood-burning cookstove. Uses minimal fuel for maximum heat.",
    category: "energy",
    inputs: %{
      "design" => "rocket mass heater plans",
      "materials" => "fire brick, metal, insulation",
      "chimney" => "vertical draft",
      "firewood" => "small diameter sticks",
      "construction" => "masonry skills"
    },
    outputs: %{
      "heat" => "cooking and heating",
      "efficient_burn" => "minimal smoke",
      "wood_efficiency" => "10x better than open fire"
    },
    constraints: ["construction_skills", "planning_required", "fire_safety"],
    icon_name: "rocket_stove",
    skill_level: "intermediate"
  },
  %{
    name: "Firewood Storage",
    description: "Properly stacked and seasoned firewood for heating and cooking efficiency.",
    category: "energy",
    inputs: %{
      "wood" => "hardwood recommended",
      "splitting" => "proper sizes",
      "seasoning" => "6-12 months dry",
      "storage" => "covered, off ground",
      "shelter" => "rain protection"
    },
    outputs: %{
      "seasoned_wood" => "efficient burning",
      "independence" => "off-grid heating",
      "cost_savings" => "reduced utility bills"
    },
    constraints: ["seasoning_time", "physical_labor", "space_requirements"],
    icon_name: "firewood_storage",
    skill_level: "beginner"
  },
  %{
    name: "Solar Cooker",
    description: "Reflective solar oven for cooking with free sunlight. Portable and efficient.",
    category: "energy",
    inputs: %{
      "sunlight" => "direct sun required",
      "reflector" => "parabolic or box design",
      "black_pot" => "heat absorption",
      "time" => "longer than conventional",
      "weather" => "sunny days only"
    },
    outputs: %{
      "cooked_food" => "zero-fuel cooking",
      "water_pasteurization" => "safe drinking water"
    },
    constraints: ["weather_dependent", "slower_cooking", "outdoor_use"],
    icon_name: "solar_cooker",
    skill_level: "beginner"
  },
  %{
    name: "Micro Hydro Generator",
    description: "Small-scale hydroelectric generation from water flow. Site-specific installation.",
    category: "energy",
    inputs: %{
      "water_source" => "flowing stream or river",
      "head" => "vertical drop required",
      "generator" => "micro hydro unit",
      "pipe" => "penstock system",
      "electrical" => "installation and storage"
    },
    outputs: %{
      "electricity" => "24/7 generation",
      "constant_power" => "predictable output"
    },
    constraints: ["site_specific", "water_rights", "technical_install", "environmental_impact"],
    icon_name: "micro_hydro",
    skill_level: "advanced"
  },
  %{
    name: "Biogas Digester",
    description: "Anaerobic digestion system producing methane from organic waste for cooking/lighting.",
    category: "energy",
    inputs: %{
      "organic_waste" => "food scraps, manure",
      "digester" => "anaerobic chamber",
      "water" => "slurry consistency",
      "temperature" => "warm conditions",
      "maintenance" => "regular feeding"
    },
    outputs: %{
      "biogas" => "methane for fuel",
      "digestate" => "liquid fertilizer",
      "reduced_waste" => "waste management"
    },
    constraints: ["technical_setup", "ongoing_feeding", "temperature_sensitive"],
    icon_name: "biogas_digester",
    skill_level: "advanced"
  }
]

# Combine all systems
all_systems = food_systems ++ water_systems ++ waste_systems ++ energy_systems

# Insert into database
Enum.each(all_systems, fn attrs ->
  Project.changeset(%Project{}, attrs)
  |> Repo.insert!()
end)

IO.puts("✓ Created #{length(all_systems)} project templates:")
IO.puts("  - Food: #{length(food_systems)}")
IO.puts("  - Water: #{length(water_systems)}")
IO.puts("  - Waste: #{length(waste_systems)}")
IO.puts("  - Energy: #{length(energy_systems)}")

