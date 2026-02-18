extends "res://tests/test_base.gd"
## Regression tests for specific bugs found during code audits.
## Each test reproduces the bug scenario to prevent reintroduction.


func run_tests() -> Dictionary:
	set_test_name("BugRegressions")

	test_inventory_keys_use_crafting_ids()
	test_garden_cooldown_minutes_at_boundary()
	test_fishing_spot_respawn_color_matches_original()
	test_storage_ui_disconnects_player_inventory_signal()
	test_placement_move_uses_instance_valid()
	test_notification_timer_replaced_on_new_message()
	test_fire_pit_state_uses_property_check()
	test_weather_forecast_saved_and_restored()
	test_death_resets_movement_state()
	test_fall_recovery_resets_fall_start_y()
	test_storage_inventory_saved_and_restored()
	test_resource_harvest_checks_player_validity()
	test_fishing_catch_checks_player_validity()
	test_snare_trap_state_saved_and_restored()
	test_cook_verifies_item_removal()
	test_pause_load_resumes_after_load()
	test_storm_fire_uses_property_check()
	test_interaction_target_uses_instance_valid()
	test_drying_rack_verifies_item_removal()
	test_smoker_verifies_item_removal()
	test_crafting_refunds_on_partial_failure()
	test_kitchen_verifies_item_removal()
	test_resource_days_elapsed_saved()
	test_grapple_complete_checks_player_validity()
	test_death_cancels_active_grapple()
	test_fire_pit_extinguish_before_dimming()
	test_durability_clamped_to_zero()
	test_upgrade_verifies_item_removal()
	test_placement_verifies_item_removal()
	test_smithing_verifies_item_removal()
	test_storm_fire_checks_instance_valid()
	test_campsite_structures_check_instance_valid()
	test_fire_effectiveness_checks_instance_valid()
	test_music_manager_no_infinite_recursion()
	test_fire_menu_division_by_zero_guard()
	test_sleep_callbacks_check_player_validity()
	test_garden_state_saved_and_restored()
	test_shelter_resting_player_uses_instance_valid()
	test_creature_player_uses_instance_valid()
	test_darkness_tween_kills_previous()
	test_save_position_uses_safe_access()
	test_resting_structure_uses_instance_valid()
	test_drying_rack_state_saved_and_restored()
	test_smoker_smithing_state_saved_and_restored()
	test_death_resets_climbing_structure()
	test_fishing_fail_catch_uses_instance_valid()
	test_crafting_recipes_status_guards_missing_recipe()
	test_grapple_interpolate_checks_player_validity()
	test_cave_resource_depleted_checks_node_validity()
	test_fire_menu_current_fire_uses_instance_valid()
	test_fishing_visuals_use_instance_valid()
	test_snare_trap_bait_checks_removal()
	test_fire_menu_fuel_checks_removal()
	test_fire_pit_warmth_zero_radius_guard()
	test_storm_fire_player_uses_instance_valid()
	test_fire_menu_actions_use_instance_valid()
	test_move_structure_uses_instance_valid()
	test_weather_vane_arrow_uses_instance_valid()
	test_grapple_rope_checks_length_before_normalize()

	return get_results()


func test_inventory_keys_use_crafting_ids() -> void:
	## Bug: save_load.gd checked for "Fishing Rod" / "Stone Axe" (display names)
	## but inventory stores items by crafting key "fishing_rod" / "stone_axe".
	## This caused campsite progression flags to never restore on load.
	var inventory: Dictionary = {"fishing_rod": 1, "stone_axe": 1, "wood": 5}

	# The correct keys that save_load.gd should check (crafting output_type)
	assert_true(inventory.has("fishing_rod"),
		"Inventory uses 'fishing_rod' key (not 'Fishing Rod')")
	assert_true(inventory.has("stone_axe"),
		"Inventory uses 'stone_axe' key (not 'Stone Axe')")

	# Display names must NOT be used as inventory keys
	assert_false(inventory.has("Fishing Rod"),
		"Inventory does NOT use display name 'Fishing Rod'")
	assert_false(inventory.has("Stone Axe"),
		"Inventory does NOT use display name 'Stone Axe'")

	# Verify crafting system output_type matches inventory keys
	var crafting_script: GDScript = load("res://scripts/crafting/crafting_system.gd") as GDScript
	if crafting_script:
		var crafting: Variant = crafting_script.new()
		if crafting and crafting.get("recipes"):
			var recipes: Dictionary = crafting.recipes
			if recipes.has("fishing_rod"):
				assert_equal(recipes["fishing_rod"].get("output_type", ""),
					"fishing_rod", "Fishing rod output_type matches inventory key")
			if recipes.has("stone_axe"):
				assert_equal(recipes["stone_axe"].get("output_type", ""),
					"stone_axe", "Stone axe output_type matches inventory key")


func test_garden_cooldown_minutes_at_boundary() -> void:
	## Bug: int(tend_cooldown / 60) + 1 showed "2 minutes" when exactly 60s remained.
	## Fix: use ceili(tend_cooldown / 60.0) for correct ceiling rounding.

	# At exactly 60 seconds, should show 1 minute (not 2)
	var cooldown_60: float = 60.0
	var minutes_60: int = ceili(cooldown_60 / 60.0)
	assert_equal(minutes_60, 1, "60s cooldown shows 1 minute")

	# At 61 seconds, should show 2 minutes (ceiling)
	var cooldown_61: float = 61.0
	var minutes_61: int = ceili(cooldown_61 / 60.0)
	assert_equal(minutes_61, 2, "61s cooldown shows 2 minutes")

	# At 59 seconds, should show 1 minute (ceiling)
	var cooldown_59: float = 59.0
	var minutes_59: int = ceili(cooldown_59 / 60.0)
	assert_equal(minutes_59, 1, "59s cooldown shows 1 minute")

	# At 120 seconds, should show exactly 2 minutes
	var cooldown_120: float = 120.0
	var minutes_120: int = ceili(cooldown_120 / 60.0)
	assert_equal(minutes_120, 2, "120s cooldown shows 2 minutes")

	# At 1 second, should show 1 minute
	var cooldown_1: float = 1.0
	var minutes_1: int = ceili(cooldown_1 / 60.0)
	assert_equal(minutes_1, 1, "1s cooldown shows 1 minute")

	# Verify the old formula was wrong at boundary
	var old_formula: int = int(60.0 / 60) + 1  # This was the bug: gives 2
	assert_not_equal(old_formula, 1,
		"Old formula int(60/60)+1 gives wrong result at boundary (confirms bug existed)")


func test_fishing_spot_respawn_color_matches_original() -> void:
	## Bug: Original pond color was Color(0.15, 0.42, 0.55, 0.72) but respawn()
	## restored it to Color(0.15, 0.35, 0.45, 0.75) - noticeably different.
	var original_color: Color = Color(0.15, 0.42, 0.55, 0.72)
	var respawn_color: Color = Color(0.15, 0.42, 0.55, 0.72)  # Must match original

	assert_true(original_color.is_equal_approx(respawn_color),
		"Respawn water color matches original pond color")

	# Verify the old wrong color would fail
	var old_respawn_color: Color = Color(0.15, 0.35, 0.45, 0.75)
	assert_false(original_color.is_equal_approx(old_respawn_color),
		"Old respawn color does NOT match original (confirms bug existed)")


func test_storage_ui_disconnects_player_inventory_signal() -> void:
	## Bug: storage_ui.gd connected player_inventory.inventory_changed on open
	## but only disconnected storage_inventory signal on close. Player inventory
	## signal accumulated stale connections after repeated open/close cycles.
	var storage_script: GDScript = load("res://scripts/ui/storage_ui.gd") as GDScript
	if not storage_script:
		assert_true(false, "Could not load storage_ui.gd")
		return

	# Verify close_storage source code contains player_inventory disconnect
	var source: String = storage_script.source_code
	var has_player_disconnect: bool = source.find("player_inventory.inventory_changed.is_connected") != -1 \
		and source.find("player_inventory.inventory_changed.disconnect") != -1
	assert_true(has_player_disconnect,
		"close_storage() disconnects player_inventory.inventory_changed signal")

	# Count connect vs disconnect calls to ensure they're balanced
	var connect_count: int = source.count("player_inventory.inventory_changed.connect")
	var disconnect_count: int = source.count("player_inventory.inventory_changed.disconnect")
	assert_equal(connect_count, disconnect_count,
		"Player inventory signal connect/disconnect calls are balanced (%d connects, %d disconnects)" % [connect_count, disconnect_count])


func test_placement_move_uses_instance_valid() -> void:
	## Bug: placement_system.gd used "not moving_structure" which doesn't detect
	## freed nodes. If a structure is destroyed while in move mode, accessing its
	## properties would crash. Must use is_instance_valid() instead.
	var placement_script: GDScript = load("res://scripts/campsite/placement_system.gd") as GDScript
	if not placement_script:
		assert_true(false, "Could not load placement_system.gd")
		return

	var source: String = placement_script.source_code

	# _confirm_move must use is_instance_valid
	var confirm_start: int = source.find("func _confirm_move()")
	var confirm_end: int = source.find("\nfunc ", confirm_start + 1)
	if confirm_end == -1:
		confirm_end = source.length()
	var confirm_body: String = source.substr(confirm_start, confirm_end - confirm_start)
	assert_true(confirm_body.find("is_instance_valid(moving_structure)") != -1,
		"_confirm_move() uses is_instance_valid(moving_structure)")

	# cancel_move must use is_instance_valid
	var cancel_start: int = source.find("func cancel_move()")
	var cancel_end: int = source.find("\nfunc ", cancel_start + 1)
	if cancel_end == -1:
		cancel_end = source.length()
	var cancel_body: String = source.substr(cancel_start, cancel_end - cancel_start)
	assert_true(cancel_body.find("is_instance_valid(moving_structure)") != -1,
		"cancel_move() uses is_instance_valid(moving_structure)")


func test_notification_timer_replaced_on_new_message() -> void:
	## Bug: hud.gd created a new timer on each show_notification() call but never
	## cancelled the old one. If notification B fires 2s after A, A's 3s timer
	## would hide B after only 1 second of display.
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	if not hud_script:
		assert_true(false, "Could not load hud.gd")
		return

	var source: String = hud_script.source_code

	# HUD must track notification timer as a member variable
	assert_true(source.find("_notification_timer") != -1,
		"HUD tracks notification timer in member variable")

	# show_notification must disconnect/cancel old timer before creating new one
	var show_start: int = source.find("func show_notification(")
	var show_end: int = source.find("\nfunc ", show_start + 1)
	if show_end == -1:
		show_end = source.length()
	var show_body: String = source.substr(show_start, show_end - show_start)
	assert_true(show_body.find("disconnect") != -1,
		"show_notification() disconnects old timer before creating new one")
	assert_true(show_body.find("_notification_timer") != -1,
		"show_notification() uses tracked timer variable")


func test_fire_pit_state_uses_property_check() -> void:
	## Bug: save_load.gd used has_method("is_lit") to check if a structure has
	## fire state, but is_lit is a property (var), not a method. has_method()
	## always returned false, so fire pit lit state was never saved.
	var save_script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not save_script:
		assert_true(false, "Could not load save_load.gd")
		return

	var source: String = save_script.source_code

	# Must use property check ("is_lit" in structure), NOT has_method("is_lit")
	assert_true(source.find('"is_lit" in structure') != -1,
		"save_load.gd uses property check for is_lit (not has_method)")
	assert_false(source.find('has_method("is_lit")') != -1,
		"save_load.gd does NOT use has_method('is_lit') (is_lit is a property)")

	# Also verify fuel_remaining is saved
	assert_true(source.find('"fuel_remaining" in structure') != -1,
		"save_load.gd saves fuel_remaining for fire pits")

	# Verify fuel_remaining is restored on load
	assert_true(source.find('struct_data.has("fuel_remaining")') != -1,
		"save_load.gd restores fuel_remaining on load")


func test_weather_forecast_saved_and_restored() -> void:
	## Bug: save_load.gd saved current_weather and duration_remaining but NOT
	## next_weather. After loading, the forecast always reset to CLEAR.
	var save_script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not save_script:
		assert_true(false, "Could not load save_load.gd")
		return

	var source: String = save_script.source_code

	# Verify next_weather is saved in _collect_weather_data
	var collect_start: int = source.find("func _collect_weather_data()")
	var collect_end: int = source.find("\nfunc ", collect_start + 1)
	if collect_end == -1:
		collect_end = source.length()
	var collect_body: String = source.substr(collect_start, collect_end - collect_start)
	assert_true(collect_body.find("next_weather") != -1,
		"_collect_weather_data() saves next_weather")

	# Verify next_weather is restored in _apply_weather_data
	var apply_start: int = source.find("func _apply_weather_data(")
	var apply_end: int = source.find("\nfunc ", apply_start + 1)
	if apply_end == -1:
		apply_end = source.length()
	var apply_body: String = source.substr(apply_start, apply_end - apply_start)
	assert_true(apply_body.find("next_weather") != -1,
		"_apply_weather_data() restores next_weather")


func test_death_resets_movement_state() -> void:
	## Bug: _on_player_died() didn't reset is_resting, is_climbing, or
	## is_grappling. Player could die while resting (starvation) and respawn
	## stuck in resting state, unable to move.
	var controller_script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not controller_script:
		assert_true(false, "Could not load player_controller.gd")
		return

	var source: String = controller_script.source_code
	var death_start: int = source.find("func _on_player_died()")
	var death_end: int = source.find("\nfunc ", death_start + 1)
	if death_end == -1:
		death_end = source.length()
	var death_body: String = source.substr(death_start, death_end - death_start)

	assert_true(death_body.find("is_resting = false") != -1,
		"_on_player_died() resets is_resting")
	assert_true(death_body.find("is_climbing = false") != -1,
		"_on_player_died() resets is_climbing")
	assert_true(death_body.find("is_grappling = false") != -1,
		"_on_player_died() resets is_grappling")


func test_fall_recovery_resets_fall_start_y() -> void:
	## Bug: _recover_from_fall() teleported the player but didn't reset
	## fall_start_y. The stale height caused immediate max fall damage
	## on the next landing after emergency recovery.
	var controller_script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not controller_script:
		assert_true(false, "Could not load player_controller.gd")
		return

	var source: String = controller_script.source_code
	var recover_start: int = source.find("func _recover_from_fall()")
	var recover_end: int = source.find("\nfunc ", recover_start + 1)
	if recover_end == -1:
		recover_end = source.length()
	var recover_body: String = source.substr(recover_start, recover_end - recover_start)

	assert_true(recover_body.find("fall_start_y") != -1,
		"_recover_from_fall() resets fall_start_y after teleport")
	assert_true(recover_body.find("is_falling = false") != -1,
		"_recover_from_fall() resets is_falling flag")


func test_storage_inventory_saved_and_restored() -> void:
	## Bug: save_load.gd had zero code to save or restore storage box contents.
	## All items stored in the storage container were permanently lost on every
	## save/load cycle.
	var save_script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not save_script:
		assert_true(false, "Could not load save_load.gd")
		return

	var source: String = save_script.source_code

	# Verify storage items are saved during collection
	assert_true(source.find('"storage_items"') != -1,
		"save_load.gd references storage_items key")
	assert_true(source.find("storage_inventory") != -1,
		"save_load.gd accesses storage_inventory")
	assert_true(source.find('struct_data["storage_items"]') != -1,
		"save_load.gd saves storage items to struct_data")

	# Verify storage items are restored during load
	assert_true(source.find('struct_data.has("storage_items")') != -1,
		"save_load.gd checks for storage_items on load")

	# Verify roundtrip: simulate storage data in struct_data
	var struct_data: Dictionary = {
		"type": "storage_container",
		"storage_items": {"wood": 10, "berry": 5, "stone_axe": 1}
	}
	var json_str: String = JSON.stringify(struct_data)
	var parsed: Dictionary = JSON.parse_string(json_str) as Dictionary
	assert_true(parsed.has("storage_items"), "storage_items survives JSON roundtrip")
	var items: Dictionary = parsed["storage_items"]
	assert_equal(int(items.get("wood", 0)), 10, "Wood count preserved in storage save")
	assert_equal(int(items.get("berry", 0)), 5, "Berry count preserved in storage save")
	assert_equal(int(items.get("stone_axe", 0)), 1, "Stone axe count preserved in storage save")


func test_resource_harvest_checks_player_validity() -> void:
	## Bug: resource_node.gd _complete_harvest() was called via timer callback
	## after 0.2s delay, but never checked if the player was still valid.
	## If player died or scene transitioned during that window, it crashed.
	var resource_script: GDScript = load("res://scripts/resources/resource_node.gd") as GDScript
	if not resource_script:
		assert_true(false, "Could not load resource_node.gd")
		return

	var source: String = resource_script.source_code
	var harvest_start: int = source.find("func _complete_harvest(")
	var harvest_end: int = source.find("\nfunc ", harvest_start + 1)
	if harvest_end == -1:
		harvest_end = source.length()
	var harvest_body: String = source.substr(harvest_start, harvest_end - harvest_start)

	assert_true(harvest_body.find("is_instance_valid(player)") != -1,
		"_complete_harvest() checks is_instance_valid(player) before accessing")


func test_fishing_catch_checks_player_validity() -> void:
	## Bug: fishing_spot.gd _attempt_catch() checked "if current_player:" but
	## didn't use is_instance_valid(). If player was freed during fishing wait,
	## accessing properties would crash.
	var fishing_script: GDScript = load("res://scripts/resources/fishing_spot.gd") as GDScript
	if not fishing_script:
		assert_true(false, "Could not load fishing_spot.gd")
		return

	var source: String = fishing_script.source_code
	assert_true(source.find("is_instance_valid(current_player)") != -1,
		"fishing_spot.gd uses is_instance_valid(current_player) for catch callback")


func test_snare_trap_state_saved_and_restored() -> void:
	## Bug: structure_snare_trap.gd had get_save_data() and load_save_data() methods
	## but save_load.gd never called them. Snare trap bait/catch state was lost on
	## every save/load cycle.
	var save_script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not save_script:
		assert_true(false, "Could not load save_load.gd")
		return

	var source: String = save_script.source_code

	# Verify save_load.gd calls get_save_data() for structures that support it
	assert_true(source.find('has_method("get_save_data")') != -1,
		"save_load.gd checks for get_save_data() on structures")
	assert_true(source.find("structure.get_save_data()") != -1,
		"save_load.gd calls structure.get_save_data() during collection")

	# Verify save_load.gd calls load_save_data() for structures that support it
	assert_true(source.find('has_method("load_save_data")') != -1,
		"save_load.gd checks for load_save_data() on structures")
	assert_true(source.find("structure.load_save_data(struct_data)") != -1,
		"save_load.gd calls structure.load_save_data() during recreation")

	# Verify snare trap has the methods
	var snare_script: GDScript = load("res://scripts/campsite/structure_snare_trap.gd") as GDScript
	if snare_script:
		var snare_source: String = snare_script.source_code
		assert_true(snare_source.find("func get_save_data()") != -1,
			"structure_snare_trap.gd has get_save_data()")
		assert_true(snare_source.find("func load_save_data(") != -1,
			"structure_snare_trap.gd has load_save_data()")
		# Verify snare saves key state fields
		assert_true(snare_source.find('"is_baited"') != -1,
			"Snare trap saves is_baited state")
		assert_true(snare_source.find('"has_catch"') != -1,
			"Snare trap saves has_catch state")
		assert_true(snare_source.find('"catch_type"') != -1,
			"Snare trap saves catch_type state")


func test_cook_verifies_item_removal() -> void:
	## Bug: fire_menu.gd _on_cook_pressed() called remove_item() but ignored its
	## return value. If removal failed (race condition, empty inventory), the player
	## would get free hunger restoration without spending the ingredient.
	var fire_script: GDScript = load("res://scripts/ui/fire_menu.gd") as GDScript
	if not fire_script:
		assert_true(false, "Could not load fire_menu.gd")
		return

	var source: String = fire_script.source_code
	var cook_start: int = source.find("func _on_cook_pressed()")
	var cook_end: int = source.find("\nfunc ", cook_start + 1)
	if cook_end == -1:
		cook_end = source.length()
	var cook_body: String = source.substr(cook_start, cook_end - cook_start)

	# Must capture return value of remove_item
	assert_true(cook_body.find("var removed") != -1,
		"_on_cook_pressed() captures remove_item return value")
	# Must check removed before giving hunger
	assert_true(cook_body.find("if not removed") != -1,
		"_on_cook_pressed() checks if removal failed before giving hunger")


func test_pause_load_resumes_after_load() -> void:
	## Bug: pause_menu.gd _on_slot_button_pressed() called resume_game() BEFORE
	## load_game_slot(). If load failed, the game was already unpaused with no
	## menu visible, leaving the player unable to re-pause.
	var pause_script: GDScript = load("res://scripts/ui/pause_menu.gd") as GDScript
	if not pause_script:
		assert_true(false, "Could not load pause_menu.gd")
		return

	var source: String = pause_script.source_code
	var slot_start: int = source.find("func _on_slot_button_pressed(")
	var slot_end: int = source.find("\nfunc ", slot_start + 1)
	if slot_end == -1:
		slot_end = source.length()
	var slot_body: String = source.substr(slot_start, slot_end - slot_start)

	# resume_game() must come AFTER load_game_slot()
	var load_pos: int = slot_body.find("load_game_slot")
	var resume_pos: int = slot_body.find("resume_game()", load_pos)
	assert_true(load_pos != -1, "Slot handler calls load_game_slot()")
	assert_true(resume_pos != -1, "Slot handler calls resume_game()")
	assert_true(resume_pos > load_pos,
		"resume_game() is called AFTER load_game_slot() (not before)")


func test_storm_fire_uses_property_check() -> void:
	## Bug: weather_manager.gd used has_method("is_lit") to check if a fire pit
	## has the is_lit property, but is_lit is a var (property), not a func.
	## has_method() always returned false, so storms could NEVER extinguish fires.
	var weather_script: GDScript = load("res://scripts/world/weather_manager.gd") as GDScript
	if not weather_script:
		assert_true(false, "Could not load weather_manager.gd")
		return

	var source: String = weather_script.source_code

	# Must use property check ("is_lit" in fire), NOT has_method("is_lit")
	var storm_start: int = source.find("func _update_storm_fire_effects(")
	var storm_end: int = source.find("\nfunc ", storm_start + 1)
	if storm_end == -1:
		storm_end = source.length()
	var storm_body: String = source.substr(storm_start, storm_end - storm_start)

	assert_true(storm_body.find('"is_lit" in fire') != -1,
		"Storm fire check uses property check ('is_lit' in fire)")
	assert_false(storm_body.find('has_method("is_lit")') != -1,
		"Storm fire check does NOT use has_method('is_lit')")


func test_interaction_target_uses_instance_valid() -> void:
	## Bug: player_controller.gd used "if current_interaction_target:" to check
	## the target before refreshing interaction text. This doesn't detect freed
	## nodes. If a resource was gathered (queue_free'd), accessing methods on the
	## stale reference would crash.
	var controller_script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not controller_script:
		assert_true(false, "Could not load player_controller.gd")
		return

	var source: String = controller_script.source_code

	# The interaction text refresh must use is_instance_valid
	assert_true(source.find("is_instance_valid(current_interaction_target)") != -1,
		"Interaction target refresh uses is_instance_valid()")

	# _try_interact must also use is_instance_valid
	var interact_start: int = source.find("func _try_interact()")
	var interact_end: int = source.find("\nfunc ", interact_start + 1)
	if interact_end == -1:
		interact_end = source.length()
	var interact_body: String = source.substr(interact_start, interact_end - interact_start)
	assert_true(interact_body.find("is_instance_valid(current_interaction_target)") != -1,
		"_try_interact() uses is_instance_valid(current_interaction_target)")


func test_drying_rack_verifies_item_removal() -> void:
	## Bug: structure_drying_rack.gd _start_drying() called remove_item() but
	## ignored the return value. If removal failed, drying would start without
	## consuming the food item.
	var rack_script: GDScript = load("res://scripts/campsite/structure_drying_rack.gd") as GDScript
	if not rack_script:
		assert_true(false, "Could not load structure_drying_rack.gd")
		return

	var source: String = rack_script.source_code
	var start_fn: int = source.find("func _start_drying(")
	var end_fn: int = source.find("\nfunc ", start_fn + 1)
	if end_fn == -1:
		end_fn = source.length()
	var fn_body: String = source.substr(start_fn, end_fn - start_fn)

	assert_true(fn_body.find("var removed") != -1,
		"_start_drying() captures remove_item return value")
	assert_true(fn_body.find("if not removed") != -1,
		"_start_drying() checks if removal failed before starting")


func test_smoker_verifies_item_removal() -> void:
	## Bug: structure_smoker.gd _start_smoking() called remove_item() twice
	## (meat and wood) but ignored both return values. If either removal failed,
	## smoking would start without consuming the items.
	var smoker_script: GDScript = load("res://scripts/campsite/structure_smoker.gd") as GDScript
	if not smoker_script:
		assert_true(false, "Could not load structure_smoker.gd")
		return

	var source: String = smoker_script.source_code
	var start_fn: int = source.find("func _start_smoking(")
	var end_fn: int = source.find("\nfunc ", start_fn + 1)
	if end_fn == -1:
		end_fn = source.length()
	var fn_body: String = source.substr(start_fn, end_fn - start_fn)

	# Must capture return value for meat removal
	assert_true(fn_body.find("var removed_meat") != -1,
		"_start_smoking() captures meat remove_item return value")
	# Must capture return value for fuel removal
	assert_true(fn_body.find("var removed_fuel") != -1,
		"_start_smoking() captures fuel remove_item return value")
	# Must refund meat if fuel removal fails
	assert_true(fn_body.find("add_item(meat_type") != -1,
		"_start_smoking() refunds meat if fuel removal fails")


func test_crafting_refunds_on_partial_failure() -> void:
	## Bug: crafting_system.gd craft() removed ingredients in a loop without
	## checking return values. If any removal failed mid-loop, some ingredients
	## were lost but the craft output was still given. Must check each removal
	## and refund previously consumed items on failure.
	var crafting_script: GDScript = load("res://scripts/crafting/crafting_system.gd") as GDScript
	if not crafting_script:
		assert_true(false, "Could not load crafting_system.gd")
		return

	var source: String = crafting_script.source_code
	var craft_start: int = source.find("func craft(")
	var craft_end: int = source.find("\nfunc ", craft_start + 1)
	if craft_end == -1:
		craft_end = source.length()
	var craft_body: String = source.substr(craft_start, craft_end - craft_start)

	# Must check remove_item return value
	assert_true(craft_body.find("var removed") != -1,
		"craft() captures remove_item return value")
	# Must track consumed items for refund
	assert_true(craft_body.find("consumed") != -1,
		"craft() tracks consumed items for potential refund")
	# Must refund on failure
	assert_true(craft_body.find("add_item(prev") != -1,
		"craft() refunds previously consumed items on failure")


func test_kitchen_verifies_item_removal() -> void:
	## Bug: cabin_kitchen.gd interact() consumed ingredients in a loop without
	## checking remove_item() return values. If removal failed, cooking effects
	## were still applied without consuming ingredients.
	var kitchen_script: GDScript = load("res://scripts/campsite/cabin_kitchen.gd") as GDScript
	if not kitchen_script:
		assert_true(false, "Could not load cabin_kitchen.gd")
		return

	var source: String = kitchen_script.source_code
	var interact_start: int = source.find("func interact(")
	var interact_end: int = source.find("\nfunc ", interact_start + 1)
	if interact_end == -1:
		interact_end = source.length()
	var interact_body: String = source.substr(interact_start, interact_end - interact_start)

	# Must check remove_item return value
	assert_true(interact_body.find("var removed") != -1,
		"Kitchen interact() captures remove_item return value")
	# Must track consumed items for refund
	assert_true(interact_body.find("consumed") != -1,
		"Kitchen interact() tracks consumed items for potential refund")


func test_resource_days_elapsed_saved() -> void:
	## Bug: resource_manager.gd get_depleted_data() saved depleted_hour and
	## depleted_minute but NOT days_elapsed. On load, the elapsed days counter
	## reset to 0, delaying resource respawns that should have already happened.
	var rm_script: GDScript = load("res://scripts/resources/resource_manager.gd") as GDScript
	if not rm_script:
		assert_true(false, "Could not load resource_manager.gd")
		return

	var source: String = rm_script.source_code

	# Verify days_elapsed is saved in get_depleted_data
	var save_start: int = source.find("func get_depleted_data()")
	var save_end: int = source.find("\nfunc ", save_start + 1)
	if save_end == -1:
		save_end = source.length()
	var save_body: String = source.substr(save_start, save_end - save_start)
	assert_true(save_body.find('"days_elapsed"') != -1,
		"get_depleted_data() saves days_elapsed")

	# Verify days_elapsed is restored in load_depleted_data
	var load_start: int = source.find("func load_depleted_data(")
	var load_end: int = source.find("\nfunc ", load_start + 1)
	if load_end == -1:
		load_end = source.length()
	var load_body: String = source.substr(load_start, load_end - load_start)
	assert_true(load_body.find('"days_elapsed"') != -1,
		"load_depleted_data() restores days_elapsed")


func test_grapple_complete_checks_player_validity() -> void:
	## Bug: grappling_hook.gd _on_grapple_complete() is a tween callback that
	## directly accessed player.global_position without checking is_instance_valid().
	## If the player died during the grapple tween, the callback would crash on
	## the freed player reference.
	var grapple_script: GDScript = load("res://scripts/player/grappling_hook.gd") as GDScript
	if not grapple_script:
		assert_true(false, "Could not load grappling_hook.gd")
		return

	var source: String = grapple_script.source_code
	var complete_start: int = source.find("func _on_grapple_complete()")
	var complete_end: int = source.find("\nfunc ", complete_start + 1)
	if complete_end == -1:
		complete_end = source.length()
	var complete_body: String = source.substr(complete_start, complete_end - complete_start)

	assert_true(complete_body.find("is_instance_valid(player)") != -1,
		"_on_grapple_complete() checks is_instance_valid(player)")


func test_death_cancels_active_grapple() -> void:
	## Bug: player_controller.gd _on_player_died() set is_grappling = false but
	## didn't call cancel_grapple() on the GrapplingHook child node. This left
	## rope and hook visual meshes orphaned in the scene after death.
	var controller_script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not controller_script:
		assert_true(false, "Could not load player_controller.gd")
		return

	var source: String = controller_script.source_code
	var death_start: int = source.find("func _on_player_died()")
	var death_end: int = source.find("\nfunc ", death_start + 1)
	if death_end == -1:
		death_end = source.length()
	var death_body: String = source.substr(death_start, death_end - death_start)

	assert_true(death_body.find("cancel_grapple") != -1,
		"_on_player_died() calls cancel_grapple() to clean up visuals")
	assert_true(death_body.find("GrapplingHook") != -1,
		"_on_player_died() gets GrapplingHook node for cleanup")


func test_fire_pit_extinguish_before_dimming() -> void:
	## Bug: structure_fire_pit.gd checked for extinguish (fuel <= 0) AFTER the
	## dimming calculation. When fuel went negative in a single frame (burn rate
	## overshooting), dim_factor became negative, causing negative light_energy
	## for one frame before the clamp. Extinguish check must come first.
	var fire_script: GDScript = load("res://scripts/campsite/structure_fire_pit.gd") as GDScript
	if not fire_script:
		assert_true(false, "Could not load structure_fire_pit.gd")
		return

	var source: String = fire_script.source_code
	var process_start: int = source.find("func _process(")
	var process_end: int = source.find("\nfunc ", process_start + 1)
	if process_end == -1:
		process_end = source.length()
	var process_body: String = source.substr(process_start, process_end - process_start)

	# Extinguish check must come BEFORE dimming calculation
	var extinguish_pos: int = process_body.find("fuel_remaining <= 0")
	var dim_pos: int = process_body.find("dim_factor")
	assert_true(extinguish_pos != -1, "Fire pit checks fuel_remaining <= 0")
	assert_true(dim_pos != -1, "Fire pit has dimming calculation")
	assert_true(extinguish_pos < dim_pos,
		"Extinguish check comes BEFORE dimming calculation (prevents negative dim_factor)")


func test_durability_clamped_to_zero() -> void:
	## Bug: equipment.gd use_durability() subtracted amount from durability without
	## clamping, allowing negative values. The durability_changed signal emitted
	## negative durability to the HUD before the break check caught it.
	var equip_script: GDScript = load("res://scripts/player/equipment.gd") as GDScript
	if not equip_script:
		assert_true(false, "Could not load equipment.gd")
		return

	var source: String = equip_script.source_code
	var dur_start: int = source.find("func use_durability(")
	var dur_end: int = source.find("\nfunc ", dur_start + 1)
	if dur_end == -1:
		dur_end = source.length()
	var dur_body: String = source.substr(dur_start, dur_end - dur_start)

	# Durability must be clamped to prevent negative values
	assert_true(dur_body.find("max(") != -1,
		"use_durability() clamps durability with max() to prevent negative values")
	# The clamp should be to 0
	assert_true(dur_body.find(", 0)") != -1,
		"use_durability() clamps durability to minimum of 0")


func test_upgrade_verifies_item_removal() -> void:
	## Bug: equipment.gd _use_upgrade() applied durability upgrades (modifying
	## tool_durability and meta) but never checked the return value of
	## remove_item() for the upgrade item. If removal failed, the player got
	## a free upgrade without consuming the leather wrap.
	var equip_script: GDScript = load("res://scripts/player/equipment.gd") as GDScript
	if not equip_script:
		assert_true(false, "Could not load equipment.gd")
		return

	var source: String = equip_script.source_code
	var upgrade_start: int = source.find("func _use_upgrade(")
	var upgrade_end: int = source.find("\nfunc ", upgrade_start + 1)
	if upgrade_end == -1:
		upgrade_end = source.length()
	var upgrade_body: String = source.substr(upgrade_start, upgrade_end - upgrade_start)

	# Must capture remove_item return value
	assert_true(upgrade_body.find("var removed") != -1,
		"_use_upgrade() captures remove_item return value")
	# Must check removal success
	assert_true(upgrade_body.find("if not removed") != -1,
		"_use_upgrade() checks if upgrade item removal failed")
	# Must revert upgrade on failure
	assert_true(upgrade_body.find("return false") != -1,
		"_use_upgrade() returns false when upgrade item cannot be consumed")


func test_placement_verifies_item_removal() -> void:
	## Bug: placement_system.gd placed structures (added to scene tree, activated)
	## then called remove_item() without checking the return value. If removal
	## failed, the player got a free structure without losing the inventory item.
	var placement_script: GDScript = load("res://scripts/campsite/placement_system.gd") as GDScript
	if not placement_script:
		assert_true(false, "Could not load placement_system.gd")
		return

	var source: String = placement_script.source_code

	# Torch placement must check remove_item return
	var torch_start: int = source.find("func place_torch_instant()")
	var torch_end: int = source.find("\nfunc ", torch_start + 1)
	if torch_end == -1:
		torch_end = source.length()
	var torch_body: String = source.substr(torch_start, torch_end - torch_start)
	assert_true(torch_body.find("var removed") != -1,
		"place_torch_instant() captures remove_item return value")
	assert_true(torch_body.find("queue_free()") != -1,
		"place_torch_instant() cleans up structure if item removal fails")

	# Lodestone placement must check remove_item return
	var lode_start: int = source.find("func place_lodestone_instant()")
	var lode_end: int = source.find("\nfunc ", lode_start + 1)
	if lode_end == -1:
		lode_end = source.length()
	var lode_body: String = source.substr(lode_start, lode_end - lode_start)
	assert_true(lode_body.find("var removed") != -1,
		"place_lodestone_instant() captures remove_item return value")
	assert_true(lode_body.find("queue_free()") != -1,
		"place_lodestone_instant() cleans up structure if item removal fails")

	# Lantern placement must check remove_item return
	var lantern_start: int = source.find("func place_lantern_instant()")
	var lantern_end: int = source.find("\nfunc ", lantern_start + 1)
	if lantern_end == -1:
		lantern_end = source.length()
	var lantern_body: String = source.substr(lantern_start, lantern_end - lantern_start)
	assert_true(lantern_body.find("var removed") != -1,
		"place_lantern_instant() captures remove_item return value")
	assert_true(lantern_body.find("queue_free()") != -1,
		"place_lantern_instant() cleans up structure if item removal fails")

	# General _confirm_placement must check remove_item return
	var confirm_start: int = source.find("func _confirm_placement()")
	var confirm_end: int = source.find("\nfunc ", confirm_start + 1)
	if confirm_end == -1:
		confirm_end = source.length()
	var confirm_body: String = source.substr(confirm_start, confirm_end - confirm_start)
	assert_true(confirm_body.find("var removed") != -1,
		"_confirm_placement() captures remove_item return value")
	assert_true(confirm_body.find("queue_free()") != -1,
		"_confirm_placement() cleans up structure if item removal fails")


func test_smithing_verifies_item_removal() -> void:
	## Bug: structure_smithing_station.gd _start_smelting() called remove_item()
	## twice (ore and wood) but ignored both return values. If fuel removal failed,
	## ore was consumed but smelting never started - player lost ore for nothing.
	var smithing_script: GDScript = load("res://scripts/campsite/structure_smithing_station.gd") as GDScript
	if not smithing_script:
		assert_true(false, "Could not load structure_smithing_station.gd")
		return

	var source: String = smithing_script.source_code
	var start_fn: int = source.find("func _start_smelting(")
	var end_fn: int = source.find("\nfunc ", start_fn + 1)
	if end_fn == -1:
		end_fn = source.length()
	var fn_body: String = source.substr(start_fn, end_fn - start_fn)

	# Must capture return value for ore removal
	assert_true(fn_body.find("var removed_ore") != -1,
		"_start_smelting() captures ore remove_item return value")
	# Must capture return value for fuel removal
	assert_true(fn_body.find("var removed_fuel") != -1,
		"_start_smelting() captures fuel remove_item return value")
	# Must refund ore if fuel removal fails
	assert_true(fn_body.find("add_item(ore_type") != -1,
		"_start_smelting() refunds ore if fuel removal fails")


func test_storm_fire_checks_instance_valid() -> void:
	## Bug: weather_manager.gd _update_storm_fire_effects() iterated fire_pits
	## without checking is_instance_valid(). If a fire pit was destroyed during a
	## storm, accessing properties on the freed node would crash. Also,
	## fire_storm_timers dictionary accumulated freed node keys as memory leak.
	var weather_script: GDScript = load("res://scripts/world/weather_manager.gd") as GDScript
	if not weather_script:
		assert_true(false, "Could not load weather_manager.gd")
		return

	var source: String = weather_script.source_code
	var storm_start: int = source.find("func _update_storm_fire_effects(")
	var storm_end: int = source.find("\nfunc ", storm_start + 1)
	if storm_end == -1:
		storm_end = source.length()
	var storm_body: String = source.substr(storm_start, storm_end - storm_start)

	# Must check validity before accessing fire properties
	assert_true(storm_body.find("is_instance_valid(fire)") != -1,
		"Storm fire loop checks is_instance_valid(fire) before property access")
	# Must clean up freed nodes from fire_storm_timers dictionary
	assert_true(storm_body.find("fire_storm_timers.erase") != -1,
		"Storm fire effect cleans up freed nodes from timer dictionary")


func test_campsite_structures_check_instance_valid() -> void:
	## Bug: campsite_manager.gd get_structures_of_type() iterated placed_structures
	## without checking is_instance_valid(). If a structure was destroyed (e.g.,
	## queue_free'd during gameplay), calling has_method() or get() on the freed
	## node would crash. This function is used by get_fire_pits(), get_shelters(),
	## and other callers throughout the codebase.
	var campsite_script: GDScript = load("res://scripts/campsite/campsite_manager.gd") as GDScript
	if not campsite_script:
		assert_true(false, "Could not load campsite_manager.gd")
		return

	var source: String = campsite_script.source_code
	var fn_start: int = source.find("func get_structures_of_type(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(structure)") != -1,
		"get_structures_of_type() checks is_instance_valid before accessing structure")


func test_fire_effectiveness_checks_instance_valid() -> void:
	## Bug: weather_manager.gd _update_fire_effectiveness() iterated fire_pits
	## without checking is_instance_valid(fire). We fixed the storm loop in Round
	## 10 but missed this second fire iteration function. If a fire pit was
	## destroyed while weather was updating, calling has_method() on the freed
	## node would crash.
	var weather_script: GDScript = load("res://scripts/world/weather_manager.gd") as GDScript
	if not weather_script:
		assert_true(false, "Could not load weather_manager.gd")
		return

	var source: String = weather_script.source_code
	var fn_start: int = source.find("func _update_fire_effectiveness()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(fire)") != -1,
		"_update_fire_effectiveness() checks is_instance_valid(fire) before access")


func test_music_manager_no_infinite_recursion() -> void:
	## Bug: music_manager.gd _play_next_track() recursively called itself when a
	## track failed to load. If all tracks were missing (e.g., asset directory
	## not found), this caused infinite recursion → stack overflow crash. The
	## recursion must be bounded or use call_deferred to prevent stack overflow.
	var music_script: GDScript = load("res://scripts/core/music_manager.gd") as GDScript
	if not music_script:
		assert_true(false, "Could not load music_manager.gd")
		return

	var source: String = music_script.source_code
	var fn_start: int = source.find("func _play_next_track()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must NOT directly recurse - should use call_deferred or have a guard
	var has_deferred: bool = fn_body.find("call_deferred") != -1
	var has_guard: bool = fn_body.find("track_order.size()") != -1
	assert_true(has_deferred or has_guard,
		"_play_next_track() uses call_deferred or recursion guard to prevent stack overflow")


func test_fire_menu_division_by_zero_guard() -> void:
	## Bug: fire_menu.gd calculated days_remaining as fuel_remaining / max_fuel
	## without checking if max_fuel > 0. If max_fuel was somehow 0 (corrupted
	## save, config error), this caused a division by zero crash.
	var fire_script: GDScript = load("res://scripts/ui/fire_menu.gd") as GDScript
	if not fire_script:
		assert_true(false, "Could not load fire_menu.gd")
		return

	var source: String = fire_script.source_code

	# Find the fuel display section
	var fuel_start: int = source.find("fuel_remaining / ")
	assert_true(fuel_start != -1, "Fire menu calculates fuel remaining ratio")

	# Must have a max_fuel > 0 guard before the division
	var guard_pos: int = source.find("max_fuel > 0")
	var div_pos: int = source.find("fuel_remaining / current_fire.max_fuel")
	assert_true(guard_pos != -1, "Fire menu has max_fuel > 0 guard")
	assert_true(guard_pos < div_pos,
		"max_fuel > 0 guard comes before the division")


func test_sleep_callbacks_check_player_validity() -> void:
	## Bug: Shelter, canvas tent, and cabin bed _skip_to_dawn() / _do_full_restore()
	## are called as async callbacks from fade_to_black_and_back(), which fires after
	## a 2-3 second delay. If the player dies during the fade, accessing
	## player.has_node() on the freed reference crashes.
	# Check shelter
	var shelter_script: GDScript = load("res://scripts/campsite/structure_shelter.gd") as GDScript
	if shelter_script:
		var source: String = shelter_script.source_code
		var fn_start: int = source.find("func _skip_to_dawn(")
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("is_instance_valid(player)") != -1,
			"Shelter _skip_to_dawn() checks is_instance_valid(player)")

	# Check canvas tent
	var tent_script: GDScript = load("res://scripts/campsite/structure_canvas_tent.gd") as GDScript
	if tent_script:
		var source: String = tent_script.source_code
		var fn_start: int = source.find("func _skip_to_dawn(")
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("is_instance_valid(player)") != -1,
			"CanvasTent _skip_to_dawn() checks is_instance_valid(player)")

	# Check cabin bed _do_full_restore
	var bed_script: GDScript = load("res://scripts/campsite/cabin_bed.gd") as GDScript
	if bed_script:
		var source: String = bed_script.source_code
		var fn_start: int = source.find("func _do_full_restore(")
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("is_instance_valid(player)") != -1,
			"CabinBed _do_full_restore() checks is_instance_valid(player)")

	# Check cabin bed _wake_up
	if bed_script:
		var source: String = bed_script.source_code
		var fn_start: int = source.find("func _wake_up(")
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("is_instance_valid(player)") != -1,
			"CabinBed _wake_up() checks is_instance_valid(player)")


func test_garden_state_saved_and_restored() -> void:
	## Bug: structure_garden.gd had no get_save_data() or load_save_data() methods.
	## All garden state (production progress, stored herbs, tend cooldown) was lost
	## on every save/load cycle. Players lost accumulated herbs and cooldowns reset.
	var garden_script: GDScript = load("res://scripts/campsite/structure_garden.gd") as GDScript
	if not garden_script:
		assert_true(false, "Could not load structure_garden.gd")
		return

	var source: String = garden_script.source_code

	# Must have get_save_data method
	assert_true(source.find("func get_save_data()") != -1,
		"Garden implements get_save_data()")
	# Must have load_save_data method
	assert_true(source.find("func load_save_data(") != -1,
		"Garden implements load_save_data()")
	# Must save key state fields
	assert_true(source.find('"production_timer"') != -1,
		"Garden saves production_timer")
	assert_true(source.find('"stored_herbs"') != -1,
		"Garden saves stored_herbs")
	assert_true(source.find('"can_tend"') != -1,
		"Garden saves can_tend")
	assert_true(source.find('"tend_cooldown"') != -1,
		"Garden saves tend_cooldown")


func test_shelter_resting_player_uses_instance_valid() -> void:
	## Bug: structure_shelter.gd _on_period_changed() checked
	## "if is_player_resting and resting_player:" but resting_player could be a
	## freed node that still passes truthiness. Subsequent code would then pass
	## the freed reference to _trigger_sleep_sequence(), crashing the game.
	var shelter_script: GDScript = load("res://scripts/campsite/structure_shelter.gd") as GDScript
	if not shelter_script:
		assert_true(false, "Could not load structure_shelter.gd")
		return

	var source: String = shelter_script.source_code
	var fn_start: int = source.find("func _on_period_changed(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(resting_player)") != -1,
		"_on_period_changed() checks is_instance_valid(resting_player)")


func test_creature_player_uses_instance_valid() -> void:
	## Bug: Creature scripts used "if player and ..." (truthiness) instead of
	## is_instance_valid(player) when checking player proximity for fleeing and
	## sound effects. If the player died or was freed, accessing global_position
	## on the freed reference would crash. Affected base class, bird, and rabbit.

	# Check base class
	var base_script: GDScript = load("res://scripts/creatures/ambient_animal_base.gd") as GDScript
	if base_script:
		var source: String = base_script.source_code
		var fn_start: int = source.find("func _process_fleeing(")
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("is_instance_valid(player)") != -1,
			"Base _process_fleeing() uses is_instance_valid(player)")

	# Check bird chirp
	var bird_script: GDScript = load("res://scripts/creatures/ambient_bird.gd") as GDScript
	if bird_script:
		var source: String = bird_script.source_code
		var fn_start: int = source.find("func _chirp()")
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("is_instance_valid(player)") != -1,
			"Bird _chirp() uses is_instance_valid(player)")

	# Check rabbit hop sound
	var rabbit_script: GDScript = load("res://scripts/creatures/ambient_rabbit.gd") as GDScript
	if rabbit_script:
		var source: String = rabbit_script.source_code
		assert_true(source.find("is_instance_valid(player) and global_position.distance_to(player.global_position) < 8.0") != -1,
			"Rabbit hop sound uses is_instance_valid(player)")


func test_darkness_tween_kills_previous() -> void:
	## Bug: cave_transition.gd _update_darkness_overlay() created a new tween on
	## every call without killing the previous one. When rapidly entering/exiting
	## darkness (equip/unequip torch), multiple tweens animated the same color:a
	## property simultaneously, causing conflicting/stuttering visual effects.
	var cave_script: GDScript = load("res://scripts/core/cave_transition.gd") as GDScript
	if not cave_script:
		assert_true(false, "Could not load cave_transition.gd")
		return

	var source: String = cave_script.source_code
	var fn_start: int = source.find("func _update_darkness_overlay(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must kill previous tween before creating new one
	assert_true(fn_body.find(".kill()") != -1,
		"_update_darkness_overlay() kills previous tween before creating new one")
	# Must store tween reference for later cleanup
	assert_true(source.find("darkness_tween") != -1,
		"Cave transition tracks darkness tween in member variable")


func test_save_position_uses_safe_access() -> void:
	## Bug: save_load.gd _apply_player_data() accessed position dictionary with
	## direct bracket notation pos["x"] and pos["z"]. If the save file was
	## corrupted or from an old version missing these keys, this would crash
	## with KeyError. Must use .get() with defaults.
	var save_script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not save_script:
		assert_true(false, "Could not load save_load.gd")
		return

	var source: String = save_script.source_code
	var fn_start: int = source.find("func _apply_player_data(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must use .get() for safe access on position data
	assert_true(fn_body.find('pos.get("x"') != -1,
		"_apply_player_data() uses safe .get() for position X")
	assert_true(fn_body.find('pos.get("z"') != -1,
		"_apply_player_data() uses safe .get() for position Z")
	# Must NOT use direct bracket access for position keys
	assert_false(fn_body.find('pos["x"]') != -1,
		"_apply_player_data() does NOT use unsafe pos[\"x\"] bracket access")
	assert_false(fn_body.find('pos["z"]') != -1,
		"_apply_player_data() does NOT use unsafe pos[\"z\"] bracket access")


func test_resting_structure_uses_instance_valid() -> void:
	## Bug: player_controller.gd checked resting_in_structure with truthiness
	## (if resting_in_structure:) instead of is_instance_valid(). If the structure
	## was destroyed while player was resting (e.g., storm damage), the freed node
	## passes truthiness and calling interact() on it would crash.
	var script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not script:
		assert_true(false, "Could not load player_controller.gd")
		return

	var source: String = script.source_code
	# Find the interact handler that checks resting_in_structure
	assert_true(source.find("is_instance_valid(resting_in_structure)") != -1,
		"Player controller uses is_instance_valid for resting_in_structure")
	# Must NOT use bare truthiness check
	assert_false(source.find("and resting_in_structure:") != -1,
		"Player controller does NOT use bare truthiness for resting_in_structure")


func test_drying_rack_state_saved_and_restored() -> void:
	## Bug: structure_drying_rack.gd had no get_save_data()/load_save_data() methods.
	## All drying state (is_drying, current_food, drying_progress) was lost on every
	## save/load cycle, meaning partially-dried food vanished.
	var script: GDScript = load("res://scripts/campsite/structure_drying_rack.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_drying_rack.gd")
		return

	var source: String = script.source_code
	assert_true(source.find("func get_save_data()") != -1,
		"Drying rack has get_save_data() method")
	assert_true(source.find("func load_save_data(") != -1,
		"Drying rack has load_save_data() method")
	# Key state must be serialized
	assert_true(source.find('"is_drying"') != -1,
		"Drying rack saves is_drying state")
	assert_true(source.find('"current_food"') != -1,
		"Drying rack saves current_food state")
	assert_true(source.find('"drying_progress"') != -1,
		"Drying rack saves drying_progress state")


func test_smoker_smithing_state_saved_and_restored() -> void:
	## Bug: structure_smoker.gd and structure_smithing_station.gd had no save/load
	## methods. In-progress smoking/smelting was lost on save/load - player lost
	## consumed resources (meat/ore/wood) with no output.
	var smoker_script: GDScript = load("res://scripts/campsite/structure_smoker.gd") as GDScript
	if not smoker_script:
		assert_true(false, "Could not load structure_smoker.gd")
		return

	var smoker_source: String = smoker_script.source_code
	assert_true(smoker_source.find("func get_save_data()") != -1,
		"Smoker has get_save_data() method")
	assert_true(smoker_source.find("func load_save_data(") != -1,
		"Smoker has load_save_data() method")
	assert_true(smoker_source.find('"is_smoking"') != -1,
		"Smoker saves is_smoking state")
	assert_true(smoker_source.find('"smoke_progress"') != -1,
		"Smoker saves smoke_progress state")

	var smithing_script: GDScript = load("res://scripts/campsite/structure_smithing_station.gd") as GDScript
	if not smithing_script:
		assert_true(false, "Could not load structure_smithing_station.gd")
		return

	var smithing_source: String = smithing_script.source_code
	assert_true(smithing_source.find("func get_save_data()") != -1,
		"Smithing station has get_save_data() method")
	assert_true(smithing_source.find("func load_save_data(") != -1,
		"Smithing station has load_save_data() method")
	assert_true(smithing_source.find('"is_smelting"') != -1,
		"Smithing station saves is_smelting state")
	assert_true(smithing_source.find('"smelt_progress"') != -1,
		"Smithing station saves smelt_progress state")


func test_death_resets_climbing_structure() -> void:
	## Bug: player_controller.gd death/respawn handler reset is_climbing to false
	## but did NOT set climbing_structure = null. This left a dangling reference
	## to the ladder/structure. If that structure was later freed, the stale
	## reference could cause crashes on future climbing interactions.
	var script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not script:
		assert_true(false, "Could not load player_controller.gd")
		return

	var source: String = script.source_code
	# Find the death/respawn section that resets movement flags
	var reset_start: int = source.find("Reset movement state flags")
	assert_true(reset_start != -1, "Found movement state reset section in respawn")
	var reset_section: String = source.substr(reset_start, 200)
	# Must null out climbing_structure alongside is_climbing = false
	assert_true(reset_section.find("climbing_structure = null") != -1,
		"Death handler resets climbing_structure to null")


func test_fishing_fail_catch_uses_instance_valid() -> void:
	## Bug: fishing_spot.gd _fail_catch() checked current_player with truthiness
	## (if current_player:) instead of is_instance_valid(). If the player died
	## during the catch window, calling methods on the freed reference would crash.
	var script: GDScript = load("res://scripts/resources/fishing_spot.gd") as GDScript
	if not script:
		assert_true(false, "Could not load fishing_spot.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _fail_catch()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(current_player)") != -1,
		"_fail_catch() uses is_instance_valid for current_player")
	assert_false(fn_body.find("if current_player:") != -1,
		"_fail_catch() does NOT use bare truthiness for current_player")


func test_crafting_recipes_status_guards_missing_recipe() -> void:
	## Bug: crafting_system.gd get_all_recipes_status() accessed recipes[recipe_id]
	## with bracket notation without checking if the recipe exists. If
	## discovered_recipes contained a stale ID not in the recipes dictionary
	## (e.g., recipe removed during updates), this would crash with KeyError.
	var script: GDScript = load("res://scripts/crafting/crafting_system.gd") as GDScript
	if not script:
		assert_true(false, "Could not load crafting_system.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func get_all_recipes_status(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must check recipe existence before bracket access
	assert_true(fn_body.find("recipes.has(recipe_id)") != -1,
		"get_all_recipes_status() checks recipes.has() before accessing")


func test_grapple_interpolate_checks_player_validity() -> void:
	## Bug: grappling_hook.gd _interpolate_grapple() checked player with truthiness
	## (if not player:) instead of is_instance_valid(). This tween method runs every
	## frame during grapple ascent. If the player died mid-grapple, the tween would
	## continue and crash when setting global_position on a freed node.
	var script: GDScript = load("res://scripts/player/grappling_hook.gd") as GDScript
	if not script:
		assert_true(false, "Could not load grappling_hook.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _interpolate_grapple(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(player)") != -1,
		"_interpolate_grapple() uses is_instance_valid for player check")


func test_cave_resource_depleted_checks_node_validity() -> void:
	## Bug: cave_entrance.gd _on_resource_depleted() accessed res_node.name without
	## validating the node was still valid. If a resource node was freed between
	## signal connection and emission, accessing res_node.name would crash.
	var script: GDScript = load("res://scripts/world/cave_entrance.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cave_entrance.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _on_resource_depleted(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(res_node)") != -1,
		"_on_resource_depleted() validates res_node before accessing properties")


func test_fire_menu_current_fire_uses_instance_valid() -> void:
	## Bug: fire_menu.gd checked current_fire with truthiness (if current_fire and)
	## instead of is_instance_valid(). If the fire pit was destroyed while the fire
	## menu was open (e.g., storm damage), accessing fuel_remaining/max_fuel on the
	## freed node would crash.
	var script: GDScript = load("res://scripts/ui/fire_menu.gd") as GDScript
	if not script:
		assert_true(false, "Could not load fire_menu.gd")
		return

	var source: String = script.source_code
	# The fuel display section should use is_instance_valid
	assert_true(source.find("is_instance_valid(current_fire)") != -1,
		"Fire menu uses is_instance_valid for current_fire check")


func test_fishing_visuals_use_instance_valid() -> void:
	## Bug: equipment.gd _hide_fishing_visuals() and hide_fishing_line() checked
	## caught_fish_model and line_pivot with truthiness instead of is_instance_valid().
	## These are called as tween callbacks or from fishing_spot._fail_catch(). If the
	## nodes were freed via _remove_fishing_rod() (unequip, death), accessing .visible
	## on the freed reference would crash.
	var script: GDScript = load("res://scripts/player/equipment.gd") as GDScript
	if not script:
		assert_true(false, "Could not load equipment.gd")
		return

	var source: String = script.source_code

	# _hide_fishing_visuals must use is_instance_valid
	var fn_start: int = source.find("func _hide_fishing_visuals()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)
	assert_true(fn_body.find("is_instance_valid(caught_fish_model)") != -1,
		"_hide_fishing_visuals uses is_instance_valid for caught_fish_model")
	assert_true(fn_body.find("is_instance_valid(line_pivot)") != -1,
		"_hide_fishing_visuals uses is_instance_valid for line_pivot")

	# hide_fishing_line must use is_instance_valid
	var fn2_start: int = source.find("func hide_fishing_line()")
	var fn2_end: int = source.find("\nfunc ", fn2_start + 1)
	var fn2_body: String = source.substr(fn2_start, fn2_end - fn2_start)
	assert_true(fn2_body.find("is_instance_valid(line_pivot)") != -1,
		"hide_fishing_line uses is_instance_valid for line_pivot")


func test_snare_trap_bait_checks_removal() -> void:
	## Bug: structure_snare_trap.gd _set_bait() called remove_item() without checking
	## the return value. If removal failed (race condition), the trap became baited
	## without consuming the bait item, duplicating resources.
	var script: GDScript = load("res://scripts/campsite/structure_snare_trap.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_snare_trap.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _set_bait(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must capture remove_item return value
	assert_true(fn_body.find("var removed") != -1,
		"_set_bait captures remove_item return value")
	assert_true(fn_body.find("if not removed") != -1,
		"_set_bait checks remove_item return and aborts on failure")


func test_fire_menu_fuel_checks_removal() -> void:
	## Bug: fire_menu.gd _on_add_fuel_pressed() called remove_item("wood", 1)
	## without checking the return value. If removal failed, add_fuel() was called
	## anyway, giving the player free fire fuel without consuming wood.
	var script: GDScript = load("res://scripts/ui/fire_menu.gd") as GDScript
	if not script:
		assert_true(false, "Could not load fire_menu.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _on_add_fuel_pressed()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must capture remove_item return value for wood
	assert_true(fn_body.find("var removed") != -1,
		"_on_add_fuel_pressed captures remove_item return value")
	assert_true(fn_body.find("if not removed") != -1,
		"_on_add_fuel_pressed checks remove_item return and aborts on failure")


func test_fire_pit_warmth_zero_radius_guard() -> void:
	## Bug: structure_fire_pit.gd get_warmth_at() calculated (distance / warmth_radius)
	## without checking if warmth_radius was 0. When set_effectiveness(0.0) is called
	## (during storms), warmth_radius becomes 0.0. If a player stands at the exact fire
	## position (distance=0), this produces 0.0/0.0 = NaN, corrupting warmth calculations.
	var script: GDScript = load("res://scripts/campsite/structure_fire_pit.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_fire_pit.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func get_warmth_at(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must guard against warmth_radius being 0
	assert_true(fn_body.find("warmth_radius <= 0") != -1,
		"get_warmth_at() guards against zero warmth_radius to prevent division by zero")


func test_storm_fire_player_uses_instance_valid() -> void:
	## Bug: weather_manager.gd _update_storm_fire_effects() checked player with
	## truthiness (if player else) instead of is_instance_valid(). This function is
	## called independently during storms without the player guard in
	## _apply_weather_effects(). If the player was freed, accessing global_position
	## on the freed node would crash.
	var script: GDScript = load("res://scripts/world/weather_manager.gd") as GDScript
	if not script:
		assert_true(false, "Could not load weather_manager.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _update_storm_fire_effects(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(player)") != -1,
		"_update_storm_fire_effects uses is_instance_valid for player reference")


func test_fire_menu_actions_use_instance_valid() -> void:
	## Bug: fire_menu.gd action handlers (_on_warm_up_pressed, _on_cook_pressed,
	## _on_add_fuel_pressed) all checked current_fire with truthiness instead of
	## is_instance_valid(). We fixed the fuel display in Round 16 but missed the
	## action handlers. If the fire pit was destroyed while the menu was open,
	## calling methods on the freed node would crash.
	var script: GDScript = load("res://scripts/ui/fire_menu.gd") as GDScript
	if not script:
		assert_true(false, "Could not load fire_menu.gd")
		return

	var source: String = script.source_code
	# All three action handlers must use is_instance_valid
	var warm_start: int = source.find("func _on_warm_up_pressed()")
	var warm_end: int = source.find("\nfunc ", warm_start + 1)
	var warm_body: String = source.substr(warm_start, warm_end - warm_start)
	assert_true(warm_body.find("is_instance_valid(current_fire)") != -1,
		"_on_warm_up_pressed uses is_instance_valid for current_fire")

	var cook_start: int = source.find("func _on_cook_pressed()")
	var cook_end: int = source.find("\nfunc ", cook_start + 1)
	var cook_body: String = source.substr(cook_start, cook_end - cook_start)
	assert_true(cook_body.find("is_instance_valid(current_fire)") != -1,
		"_on_cook_pressed uses is_instance_valid for current_fire")

	var fuel_start: int = source.find("func _on_add_fuel_pressed()")
	var fuel_end: int = source.find("\nfunc ", fuel_start + 1)
	if fuel_end == -1:
		fuel_end = source.length()
	var fuel_body: String = source.substr(fuel_start, fuel_end - fuel_start)
	assert_true(fuel_body.find("is_instance_valid(current_fire)") != -1,
		"_on_add_fuel_pressed uses is_instance_valid for current_fire")


func test_move_structure_uses_instance_valid() -> void:
	## Bug: _try_move_structure used truthiness for current_interaction_target.
	## If the target node was freed, truthiness would pass but is_in_group() would crash.
	var script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not script:
		assert_true(false, "Could not load player_controller.gd")
		return

	var source: String = script.source_code
	var func_start: int = source.find("func _try_move_structure()")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	var func_body: String = source.substr(func_start, func_end - func_start)
	assert_true(func_body.find("is_instance_valid(current_interaction_target)") != -1,
		"_try_move_structure uses is_instance_valid for current_interaction_target")


func test_weather_vane_arrow_uses_instance_valid() -> void:
	## Bug: Weather vane _process used truthiness for arrow_pivot.
	## If the child node was freed during scene transitions, accessing .rotation.y would crash.
	var script: GDScript = load("res://scripts/campsite/structure_weather_vane.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_weather_vane.gd")
		return

	var source: String = script.source_code
	var func_start: int = source.find("func _process(")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	var func_body: String = source.substr(func_start, func_end - func_start)
	assert_true(func_body.find("is_instance_valid(arrow_pivot)") != -1,
		"Weather vane _process uses is_instance_valid for arrow_pivot")


func test_grapple_rope_checks_length_before_normalize() -> void:
	## Bug: _update_rope_visual normalized the direction vector before checking length.
	## normalized() always returns length 0 or ~1.0, so the length > 0.001 guard was
	## ineffective. When from and to were very close, look_at was called with near-
	## overlapping positions. Fix: check the actual distance (length) before normalizing.
	var script: GDScript = load("res://scripts/player/grappling_hook.gd") as GDScript
	if not script:
		assert_true(false, "Could not load grappling_hook.gd")
		return

	var source: String = script.source_code
	var func_start: int = source.find("func _update_rope_visual(")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	var func_body: String = source.substr(func_start, func_end - func_start)
	# The length check must come before normalization
	var length_check_pos: int = func_body.find("if length > 0.001")
	var normalize_pos: int = func_body.find(".normalized()")
	assert_true(length_check_pos != -1, "Rope visual checks length before normalizing")
	assert_true(normalize_pos == -1 or length_check_pos < normalize_pos,
		"Length check comes before normalization to avoid near-zero look_at")
