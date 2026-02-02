extends RefCounted
class_name StructureData
## Static data defining all structure types and their properties.

# Structure definitions
const STRUCTURES: Dictionary = {
	"fire_pit": {
		"name": "Fire Pit",
		"scene": "res://scenes/campsite/structures/fire_pit.tscn",
		"item_required": "campfire_kit",
		"provides_warmth": true,
		"provides_light": true,
		"warmth_radius": 5.0,
		"category": "fire"
	},
	"basic_shelter": {
		"name": "Basic Shelter",
		"scene": "res://scenes/campsite/structures/basic_shelter.tscn",
		"item_required": "shelter_kit",
		"provides_protection": true,
		"protection_radius": 3.0,
		"category": "shelter"
	},
	"storage_container": {
		"name": "Storage Box",
		"scene": "res://scenes/campsite/structures/storage_container.tscn",
		"item_required": "storage_box",
		"has_inventory": true,
		"inventory_slots": 20,
		"category": "storage"
	},
	"crafting_bench": {
		"name": "Crafting Bench",
		"scene": "res://scenes/campsite/structures/crafting_bench.tscn",
		"item_required": "crafting_bench_kit",
		"category": "utility"
	},
	"drying_rack": {
		"name": "Drying Rack",
		"scene": "res://scenes/campsite/structures/drying_rack.tscn",
		"item_required": "drying_rack_kit",
		"category": "food"
	},
	"herb_garden": {
		"name": "Herb Garden",
		"scene": "res://scenes/campsite/structures/herb_garden.tscn",
		"item_required": "garden_plot_kit",
		"category": "food"
	},
	"canvas_tent": {
		"name": "Canvas Tent",
		"scene": "res://scenes/campsite/structures/canvas_tent.tscn",
		"item_required": "canvas_tent_kit",
		"provides_protection": true,
		"protection_radius": 4.0,
		"category": "shelter",
		"min_camp_level": 2
	},
	"cabin": {
		"name": "Log Cabin",
		"scene": "res://scenes/campsite/structures/cabin.tscn",
		"item_required": "cabin_kit",
		"provides_protection": true,
		"protection_radius": 8.0,
		"category": "shelter",
		"min_camp_level": 3
	},
	"rope_ladder": {
		"name": "Rope Ladder",
		"scene": "res://scenes/campsite/structures/rope_ladder.tscn",
		"item_required": "rope_ladder_kit",
		"category": "utility"
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
	"rope_ladder_kit"
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
