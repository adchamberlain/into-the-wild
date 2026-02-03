extends ResourceNode
class_name OreNode
## An ore deposit that can be mined for metal resources.

func _ready() -> void:
	super._ready()
	resource_type = "iron_ore"
	resource_amount = 2
	interaction_text = "Mine"
	required_tool = "axe"
	chops_required = 3
	secondary_resource_type = "river_rock"
	secondary_resource_amount = 1
	# Ore nodes are placed by chunk manager, don't auto-adjust
	adjust_to_terrain = false
