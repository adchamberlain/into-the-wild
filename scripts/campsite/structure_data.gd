extends RefCounted
class_name StructureData
## Static data defining all structure types and their properties.

# Structure definitions
const STRUCTURES: Dictionary = {
	"fire_pit": {
		"name": "Fire Pit",
		"scene": "",
		"item_required": "campfire_kit",
		"provides_warmth": true,
		"provides_light": true,
		"warmth_radius": 5.0,
		"category": "fire",
		"footprint_radius": 0.85
	},
	"basic_shelter": {
		"name": "Basic Shelter",
		"scene": "",
		"item_required": "shelter_kit",
		"provides_protection": true,
		"protection_radius": 3.0,
		"category": "shelter",
		"footprint_radius": 1.4
	},
	"storage_container": {
		"name": "Storage Box",
		"scene": "",
		"item_required": "storage_box",
		"has_inventory": true,
		"inventory_slots": 20,
		"category": "storage",
		"footprint_radius": 0.6
	},
	"crafting_bench": {
		"name": "Crafting Bench",
		"scene": "",
		"item_required": "crafting_bench_kit",
		"category": "utility",
		"footprint_radius": 0.7
	},
	"drying_rack": {
		"name": "Drying Rack",
		"scene": "res://scenes/campsite/structures/drying_rack.tscn",
		"item_required": "drying_rack_kit",
		"category": "food",
		"footprint_radius": 0.8
	},
	"herb_garden": {
		"name": "Herb Garden",
		"scene": "res://scenes/campsite/structures/herb_garden.tscn",
		"item_required": "garden_plot_kit",
		"category": "food",
		"footprint_radius": 1.25
	},
	"canvas_tent": {
		"name": "Canvas Tent",
		"scene": "res://scenes/campsite/structures/canvas_tent.tscn",
		"item_required": "canvas_tent_kit",
		"provides_protection": true,
		"protection_radius": 4.0,
		"category": "shelter",
		"min_camp_level": 2,
		"footprint_radius": 2.0
	},
	"cabin": {
		"name": "Log Cabin",
		"scene": "res://scenes/campsite/structures/cabin.tscn",
		"item_required": "cabin_kit",
		"provides_protection": true,
		"protection_radius": 8.0,
		"category": "shelter",
		"min_camp_level": 3,
		"footprint_radius": 4.0
	},
	"rope_ladder": {
		"name": "Rope Ladder",
		"scene": "res://scenes/campsite/structures/rope_ladder.tscn",
		"item_required": "rope_ladder_kit",
		"category": "utility",
		"footprint_radius": 0.5
	},
	"snare_trap": {
		"name": "Snare Trap",
		"scene": "res://scenes/campsite/structures/snare_trap.tscn",
		"item_required": "snare_trap_kit",
		"category": "hunting",
		"min_camp_level": 2,
		"footprint_radius": 0.8
	},
	"smithing_station": {
		"name": "Smithing Station",
		"scene": "res://scenes/campsite/structures/smithing_station.tscn",
		"item_required": "smithing_station_kit",
		"category": "crafting",
		"min_camp_level": 3,
		"footprint_radius": 1.2
	},
	"smoker": {
		"name": "Smoker",
		"scene": "res://scenes/campsite/structures/smoker.tscn",
		"item_required": "smoker_kit",
		"category": "food",
		"min_camp_level": 3,
		"footprint_radius": 1.0
	},
	"weather_vane": {
		"name": "Weather Vane",
		"scene": "res://scenes/campsite/structures/weather_vane.tscn",
		"item_required": "weather_vane_kit",
		"category": "utility",
		"min_camp_level": 3,
		"footprint_radius": 0.5
	},
	"placed_torch": {
		"name": "Torch",
		"scene": "res://scenes/campsite/structures/placed_torch.tscn",
		"item_required": "torch",
		"provides_light": true,
		"category": "utility",
		"footprint_radius": 0.3,
		"reclaimable": true
	}
}

# Items that can be placed as structures
const PLACEABLE_ITEMS: Array[String] = [
	"campfire_kit",
	"shelter_kit",
	"storage_box",
	"crafting_bench_kit",
	"drying_rack_kit",
	"garden_plot_kit",
	"canvas_tent_kit",
	"cabin_kit",
	"rope_ladder_kit",
	"snare_trap_kit",
	"smithing_station_kit",
	"smoker_kit",
	"weather_vane_kit",
	"torch"
]


## Get structure data by structure type.
static func get_structure(structure_type: String) -> Dictionary:
	return STRUCTURES.get(structure_type, {})


## Get structure type for an item (reverse lookup).
static func get_structure_for_item(item_type: String) -> String:
	for structure_type: String in STRUCTURES:
		var data: Dictionary = STRUCTURES[structure_type]
		if data.get("item_required", "") == item_type:
			return structure_type
	return ""


## Check if an item is placeable as a structure.
static func is_placeable_item(item_type: String) -> bool:
	return item_type in PLACEABLE_ITEMS


## Get the scene path for a structure type.
static func get_scene_path(structure_type: String) -> String:
	var data: Dictionary = get_structure(structure_type)
	return data.get("scene", "")


## Get the footprint radius for a structure type.
static func get_footprint_radius(structure_type: String) -> float:
	var data: Dictionary = get_structure(structure_type)
	return data.get("footprint_radius", 1.0)
