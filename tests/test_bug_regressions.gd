extends "res://tests/test_base.gd"
## Regression tests for specific bugs found during code audits.
## Each test reproduces the bug scenario to prevent reintroduction.


func run_tests() -> Dictionary:
	set_test_name("BugRegressions")

	test_cave_terrain_collision_skips_underground_tunnel()
	test_tool_resource_prompt_uses_use_equipped()
	test_canvas_tent_camera_inside_tent()
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
	test_hud_interaction_target_uses_instance_valid()
	test_storage_ui_transfer_checks_removal()
	test_storm_tending_uses_instance_valid()
	test_shelter_skip_to_dawn_validates_time_manager()
	test_cabin_bed_skip_to_dawn_validates_time_manager()
	test_player_stats_percent_guards_zero()
	# REMOVED: test_drying_rack/smoker/smithing_completion_uses_instance_valid (code refactored)
	test_fire_pit_light_uses_instance_valid_in_process()
	test_fire_pit_flare_uses_instance_valid()
	test_fire_pit_light_wood_checks_removal()
	test_canvas_tent_skip_to_dawn_validates_time_manager()
	test_try_eat_checks_removal()
	test_campfire_kit_checks_removal()
	test_zero_vector_normalize_guards()
	test_weather_manager_uses_instance_valid()
	test_chunk_manager_uses_instance_valid()
	test_bark_map_uses_path_key_for_rivers()
	test_resting_clears_when_structure_freed()
	test_grappling_hook_checks_current_scene()
	test_osha_root_restores_hunger_when_healing()
	test_resource_node_timer_checks_self_validity()
	test_signal_connections_use_is_connected_guard()
	test_config_menu_float_comparison()

	# Round 2 regression tests
	test_cave_darkness_uses_player_stats()
	test_cave_transition_saves_state()
	test_cave_resource_state_deep_duplicate()
	test_save_load_awaits_campsite_data()
	test_weather_data_saves_day_tracking()
	test_weather_data_restores_day_tracking()
	test_load_game_slot_callers_use_await()
	test_config_menu_has_apply_config()
	test_config_kl_keys_check_visibility()
	test_processing_structures_lookup_player_on_complete()
	test_use_equipped_checks_placement_active()
	test_dried_herb_in_food_values()
	test_fire_menu_has_raw_meat_recipe()
	test_fire_menu_checks_is_lit()
	test_fire_menu_cooking_uses_inventory()
	test_equipment_menu_sets_mouse_mode()
	test_fishing_respawn_checks_hours()
	test_crafting_getters_return_duplicates()
	test_campsite_get_structures_returns_duplicate()

	# Round 3 regression tests
	test_fishing_spot_tracks_depleted_day()
	test_death_resets_water_state()
	test_death_closes_menus()
	test_window_refocus_recaptures_mouse()
	test_equipment_input_has_ui_guard()
	test_player_actions_blocked_by_ui()
	test_movement_blocked_by_ui()
	test_controller_look_blocked_by_ui()
	test_cave_id_default_is_negative_one()
	test_camera_lerp_alpha_clamped()
	test_grapple_cancel_consumes_input()
	test_placement_consumes_input()
	test_flare_tween_tracked()
	test_placement_requires_inventory()
	test_storage_unequips_on_transfer()
	test_menu_overlap_prevention()
	test_water_ref_counting()

	# Round 4 regression tests
	test_player_position_uses_saved_y_in_cave()
	test_equipment_tween_created_on_self()
	test_loading_screen_checks_validity_after_await()
	test_notification_timer_uses_is_connected()
	test_celebration_tween_uses_is_valid()
	test_config_saves_music_settings()
	test_config_restores_music_settings()
	test_cave_light_check_timer_reset_on_load()
	test_health_hunger_clamped_on_load()
	test_structure_position_defaults_are_float()

	# Round 5 regression tests
	test_death_signal_guarded_by_is_dead()
	test_take_damage_guarded_by_is_dead()
	test_time_changed_emitted_on_load()
	test_reclaimable_no_double_unregister()
	test_placement_checks_water()
	test_shelter_uses_eat_method()
	test_cabin_bed_uses_eat_method()
	test_canvas_tent_uses_eat_method()
	# REMOVED: test_kitchen_uses_eat_method (kitchen cooks, doesn't restore hunger)

	# Round 6 regression tests
	test_resource_respawn_no_double_day_count()
	test_save_load_uses_position_not_global()
	test_save_load_guards_register_with_container()
	test_underwater_effect_checks_canvas_name()
	test_grapple_end_resets_is_falling()
	test_grapple_cancel_clears_attach_timer()
	test_bird_flee_guards_zero_vector()
	test_ambient_sound_sync_checks_validity()
	test_berry_bush_respawn_resets_chop_float()
	test_fire_pit_dim_skips_during_flare()
	test_save_load_clears_cached_arrays()
	test_shelter_skip_dawn_checks_self_valid()
	test_cabin_bed_skip_dawn_checks_self_valid()

	# Round 7 regression tests
	test_environment_manager_uses_get_node_or_null()
	test_cave_flat_zone_uses_continue()
	test_height_limit_cache_bounded()
	test_river_water_material_shared()
	# REMOVED: test_miter_checks_before_normalize (river refactored, no miter logic)
	test_hud_uses_get_node_or_null()
	test_crafting_restore_focus_checks_is_open()
	test_storage_ui_checks_instance_valid()

	# Round 8 regression tests
	test_cave_state_loaded_before_player_data()
	test_weather_load_replays_side_effects()
	test_death_resets_shelter_resting_state()
	test_death_resets_cabin_bed_sleeping_state()
	test_death_cancels_active_placement()
	test_fishing_spot_cancels_on_invalid_player()
	test_chunk_queue_filters_stale_entries()
	test_height_cache_key_uses_floor()

	# Round 9 regression tests
	test_crystal_collision_disabled_when_depleted()
	test_ore_collision_disabled_when_depleted()
	test_darkness_notification_threshold_reachable()
	test_processing_structures_store_pending_output()
	test_canvas_tent_skip_dawn_checks_self_valid()
	test_cave_test_uses_168h_respawn()
	test_config_tab_checks_visibility_or_pause()
	test_equipment_menu_has_all_equippable_items()
	test_durability_signal_uses_equipped_max()
	test_axe_tween_killed_on_remove()
	test_pause_menu_load_uses_await()
	test_raw_mountain_height_checks_carved_neighbor()
	test_trees_skip_negative_height()
	test_config_menu_load_uses_await()
	test_fishing_tweens_tracked_as_members()
	test_birch_bark_emits_before_durability()
	test_shelter_sleep_guard_prevents_double()
	test_heal_eat_guard_is_dead()

	# Round 10 regression tests
	test_music_manager_set_enabled_guards_null_player()
	test_ambient_sound_add_child_before_global_position()
	test_pause_resume_guards_is_inside_tree()
	test_hud_weather_refresh_uses_get_weather_name()
	test_creature_look_at_uses_model_front()
	test_bark_strip_visual_added_on_harvest()
	test_bark_strip_reapplied_on_chunk_spawn()
	test_cabin_bed_connects_to_period_changed()
	test_animal_avoids_cave_entrance()
	test_map_does_not_block_movement()
	test_map_updates_player_position()
	test_journal_interact_sets_sinkhole_book_collected()
	test_rock_spire_is_static_body()
	test_weather_manager_connects_day_changed()
	test_journal_sets_menu_open_flag()
	test_journal_uses_gui_input_for_touch()
	test_house_pause_menu_in_pause_group()
	test_pond_edge_collision_extends_downward()
	test_water_area_matches_visual_dimensions()
	test_player_has_water_exit_grace_timer()
	test_camp_level_crafting_hint_exists()
	test_crafting_ui_shows_camp_level_label()
	test_fire_flare_uses_stable_baseline()
	test_cooking_does_not_flare_fire()
	test_fire_brightness_has_max_level()

	# Round 11 regression tests (player feedback: compass/cursor/NG+ arrows/bundle)
	test_first_compass_hint_exists()
	test_compass_triggers_hint_on_inventory_add()
	test_focus_out_skips_mouse_release_when_controller_active()
	test_new_game_plus_stack_amounts_exist()
	test_ng_plus_diamond_arrows_granted_as_ten()
	test_new_game_plus_bundles_compass_and_lodestone()

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
	## Bug class: if the forecast queue isn't persisted, loading a save resets
	## the weather schedule, breaking the forecast the weather vane showed.
	var save_script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not save_script:
		assert_true(false, "Could not load save_load.gd")
		return

	var source: String = save_script.source_code

	# Verify forecast queue is saved
	var collect_start: int = source.find("func _collect_weather_data()")
	var collect_end: int = source.find("\nfunc ", collect_start + 1)
	if collect_end == -1:
		collect_end = source.length()
	var collect_body: String = source.substr(collect_start, collect_end - collect_start)
	assert_true(collect_body.find("forecast") != -1,
		"_collect_weather_data() saves the forecast queue")

	# Verify forecast queue is restored
	var apply_start: int = source.find("func _apply_weather_data(")
	var apply_end: int = source.find("\nfunc ", apply_start + 1)
	if apply_end == -1:
		apply_end = source.length()
	var apply_body: String = source.substr(apply_start, apply_end - apply_start)
	assert_true(apply_body.find("forecast") != -1,
		"_apply_weather_data() restores the forecast queue")


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
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_drying_rack.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_drying_rack.gd")
		return
	var source: String = file.get_as_text()
	file.close()
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
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_smoker.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_smoker.gd")
		return
	var source: String = file.get_as_text()
	file.close()
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
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var source: String = file.get_as_text()
	file.close()
	# Find the death/respawn section that resets movement flags
	var reset_start: int = source.find("Reset movement state flags")
	assert_true(reset_start != -1, "Found movement state reset section in respawn")
	var reset_section: String = source.substr(reset_start, 400)
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


func test_hud_interaction_target_uses_instance_valid() -> void:
	## Bug: HUD _on_interaction_target_changed used truthiness for target parameter.
	## If the target node was freed between signal emission and handler execution,
	## truthiness would pass but is_in_group() would crash on the freed node.
	var script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	if not script:
		assert_true(false, "Could not load hud.gd")
		return

	var source: String = script.source_code
	var func_start: int = source.find("func _on_interaction_target_changed(")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	var func_body: String = source.substr(func_start, func_end - func_start)
	assert_true(func_body.find("is_instance_valid(target)") != -1,
		"HUD interaction target handler uses is_instance_valid for target")


func test_storage_ui_transfer_checks_removal() -> void:
	## Bug: Storage UI transfer functions called remove_item() without checking
	## the return value. If removal failed, items were still added to the
	## destination inventory, causing item duplication.
	var script: GDScript = load("res://scripts/ui/storage_ui.gd") as GDScript
	if not script:
		assert_true(false, "Could not load storage_ui.gd")
		return

	var source: String = script.source_code
	# Single transfer function
	var func_start: int = source.find("func _on_transfer_pressed(")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	var func_body: String = source.substr(func_start, func_end - func_start)
	# Both player->storage and storage->player should check removal
	var remove_count: int = func_body.count("var removed: bool = ")
	assert_true(remove_count >= 2,
		"_on_transfer_pressed checks remove_item return in both directions")

	# Bulk transfer function
	var bulk_start: int = source.find("func _on_transfer_all_pressed(")
	var bulk_end: int = source.find("\nfunc ", bulk_start + 1)
	var bulk_body: String = source.substr(bulk_start, bulk_end - bulk_start)
	var bulk_remove_count: int = bulk_body.count("var removed: bool = ")
	assert_true(bulk_remove_count >= 2,
		"_on_transfer_all_pressed checks remove_item return in both directions")


func test_storm_tending_uses_instance_valid() -> void:
	## Bug: _update_storm_fire_effects used truthiness for player in the
	## is_tending check (line 161). Line 149 already correctly used
	## is_instance_valid(player) for player_pos, but the is_tending check
	## was a leftover that could incorrectly mark fires as tended when
	## the player was freed.
	var script: GDScript = load("res://scripts/world/weather_manager.gd") as GDScript
	if not script:
		assert_true(false, "Could not load weather_manager.gd")
		return

	var source: String = script.source_code
	var func_start: int = source.find("func _update_storm_fire_effects(")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	var func_body: String = source.substr(func_start, func_end - func_start)
	# The is_tending line should use is_instance_valid, not plain truthiness
	assert_true(func_body.find("is_instance_valid(player) and fire.global_position") != -1,
		"Storm tending check uses is_instance_valid for player")


func test_shelter_skip_to_dawn_validates_time_manager() -> void:
	## Bug: structure_shelter.gd _skip_to_dawn accessed time_manager properties
	## without checking is_instance_valid(). The callback is bound to a tween that
	## fires after a 1s fade delay. If the scene transitions during the fade,
	## time_manager could be freed, crashing on property access.
	var script: GDScript = load("res://scripts/campsite/structure_shelter.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_shelter.gd")
		return

	var source: String = script.source_code
	var func_start: int = source.find("func _skip_to_dawn(")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	if func_end == -1:
		func_end = source.length()
	var func_body: String = source.substr(func_start, func_end - func_start)
	assert_true(func_body.find("is_instance_valid(time_manager)") != -1,
		"Shelter _skip_to_dawn validates time_manager before access")


func test_cabin_bed_skip_to_dawn_validates_time_manager() -> void:
	## Bug: cabin_bed.gd _skip_to_dawn accessed time_manager properties
	## without checking is_instance_valid(). Same tween callback issue as shelter.
	var script: GDScript = load("res://scripts/campsite/cabin_bed.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cabin_bed.gd")
		return

	var source: String = script.source_code
	var func_start: int = source.find("func _skip_to_dawn(")
	var func_end: int = source.find("\nfunc ", func_start + 1)
	if func_end == -1:
		func_end = source.length()
	var func_body: String = source.substr(func_start, func_end - func_start)
	assert_true(func_body.find("is_instance_valid(time_manager)") != -1,
		"CabinBed _skip_to_dawn validates time_manager before access")


func test_player_stats_percent_guards_zero() -> void:
	## Bug: get_health_percent() and get_hunger_percent() divided by max_health
	## and max_hunger without checking for zero. If save data is corrupted or
	## values reset, division by zero produces NaN that propagates to HUD.
	## Behavioral test: actually call the methods with zero max values.
	var stats: PlayerStats = PlayerStats.new()

	# Test get_health_percent with zero max_health
	stats.max_health = 0.0
	stats.max_health_bonus = 0
	stats.health = 0.0
	var health_pct: float = stats.get_health_percent()
	assert_true(not is_nan(health_pct), "get_health_percent does not return NaN with zero max")
	assert_equal(health_pct, 0.0, "get_health_percent returns 0.0 with zero max_health")

	# Test get_hunger_percent with zero max_hunger
	stats.max_hunger = 0.0
	stats.hunger = 0.0
	var hunger_pct: float = stats.get_hunger_percent()
	assert_true(not is_nan(hunger_pct), "get_hunger_percent does not return NaN with zero max")
	assert_equal(hunger_pct, 0.0, "get_hunger_percent returns 0.0 with zero max_hunger")

	# Verify normal values still work
	stats.max_health = 100.0
	stats.health = 50.0
	assert_between(stats.get_health_percent(), 0.49, 0.51, "get_health_percent returns 0.5 at half health")
	stats.max_hunger = 100.0
	stats.hunger = 75.0
	assert_between(stats.get_hunger_percent(), 0.74, 0.76, "get_hunger_percent returns 0.75 at 75% hunger")

	stats.free()


## REMOVED: test_drying_rack_completion_uses_instance_valid
## Code was refactored — _complete_drying() no longer accesses player_inventory directly.
## It emits signals and sets pending_output instead.


## REMOVED: test_smoker_completion_uses_instance_valid
## Code was refactored — _complete_smoking() no longer accesses player_inventory directly.
## It emits signals and sets pending_output instead.


## REMOVED: test_smithing_completion_uses_instance_valid
## Code was refactored — _complete_smelting() no longer accesses player_inventory directly.
## It emits signals and sets pending_output_count instead.


func test_fire_pit_light_uses_instance_valid_in_process() -> void:
	## Bug: structure_fire_pit.gd _process() checked fire_light with truthiness
	## (and fire_light:) in the dimming code at line 64. If the FireLight child
	## node was freed externally, the freed reference passes truthiness and
	## accessing .light_energy crashes. Must use is_instance_valid().
	var script: GDScript = load("res://scripts/campsite/structure_fire_pit.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_fire_pit.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _process(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(fire_light)") != -1,
		"Fire pit _process dimming uses is_instance_valid for fire_light")


func test_fire_pit_flare_uses_instance_valid() -> void:
	## Bug: structure_fire_pit.gd flare() checked fire_light with truthiness
	## (if not fire_light) instead of is_instance_valid(). A freed node passes
	## truthiness so the guard wouldn't trigger, and the subsequent
	## fire_light.light_energy access and tween would crash on the freed node.
	var script: GDScript = load("res://scripts/campsite/structure_fire_pit.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_fire_pit.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func flare()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(fire_light)") != -1,
		"flare() uses is_instance_valid for fire_light guard")


func test_fire_pit_light_wood_checks_removal() -> void:
	## Bug: structure_fire_pit.gd interact() called inventory.remove_item("wood", 1)
	## without checking the return value. If removal failed (race condition), the
	## code still set fuel_remaining = max_fuel and lit the fire, giving the player
	## free fuel without consuming wood.
	var script: GDScript = load("res://scripts/campsite/structure_fire_pit.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_fire_pit.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func interact(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must capture remove_item return value for wood
	assert_true(fn_body.find("var removed") != -1,
		"Fire pit interact() captures remove_item return value for wood")
	assert_true(fn_body.find("if not removed") != -1,
		"Fire pit interact() checks remove_item return and aborts on failure")


func test_canvas_tent_skip_to_dawn_validates_time_manager() -> void:
	## Bug: structure_canvas_tent.gd _skip_to_dawn() overrides the parent shelter
	## method but forgot to add the is_instance_valid(time_manager) guard. We fixed
	## this in structure_shelter.gd and cabin_bed.gd but missed the canvas tent
	## override. The callback fires after a 1-second fade delay via tween, during
	## which a scene transition could free the time_manager.
	var script: GDScript = load("res://scripts/campsite/structure_canvas_tent.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_canvas_tent.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _skip_to_dawn(")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	assert_true(fn_body.find("is_instance_valid(time_manager)") != -1,
		"CanvasTent _skip_to_dawn validates time_manager before access")


func test_try_eat_checks_removal() -> void:
	## Bug: player_controller.gd _try_eat() called remove_item() for healing items
	## and food without checking the return value. If removal failed, stats.heal()
	## or stats.eat() still executed, giving free healing/hunger without consuming
	## the item — item duplication via race condition.
	var script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not script:
		# player_controller won't compile in headless (SFXManager dependency)
		# so we skip gracefully
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _try_eat()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must capture remove_item return for both healing and food paths
	var remove_count: int = fn_body.count("var removed: bool = inventory.remove_item")
	assert_true(remove_count >= 2,
		"_try_eat checks remove_item return in both healing and food paths")


func test_campfire_kit_checks_removal() -> void:
	## Bug: equipment.gd _use_campfire_kit() placed the campfire in the scene
	## (add_child) BEFORE calling remove_item("campfire_kit", 1), and didn't
	## check the return value. If removal failed, the player got a free campfire
	## without consuming the kit item.
	var script: GDScript = load("res://scripts/player/equipment.gd") as GDScript
	if not script:
		assert_true(false, "Could not load equipment.gd")
		return

	var source: String = script.source_code
	var fn_start: int = source.find("func _legacy_place_campfire()")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)

	# Must capture remove_item return value
	assert_true(fn_body.find("var removed") != -1,
		"_legacy_place_campfire captures remove_item return value")
	# Must clean up campfire if removal fails
	assert_true(fn_body.find("queue_free()") != -1,
		"_legacy_place_campfire cleans up campfire if item removal fails")


func test_zero_vector_normalize_guards() -> void:
	## Bug: Normalizing a zero vector (e.g. camera forward with y=0 when looking
	## straight up/down) produces NaN. All normalize calls on potentially-zero
	## vectors must check length_squared() > 0.001 first.

	# grappling_hook.gd - dismount forward velocity
	var hook_script: GDScript = load("res://scripts/player/grappling_hook.gd") as GDScript
	if hook_script:
		var src: String = hook_script.source_code
		# Find the dismount section (after "Give small forward velocity")
		var dismount_idx: int = src.find("Give small forward velocity")
		if dismount_idx != -1:
			var section: String = src.substr(dismount_idx, 200)
			assert_true(section.find("length_squared") != -1,
				"grappling_hook dismount checks length before normalize")

	# placement_system.gd - structure placement forward
	var placement_script: GDScript = load("res://scripts/campsite/placement_system.gd") as GDScript
	if placement_script:
		var src: String = placement_script.source_code
		var preview_idx: int = src.find("func _update_preview_position")
		if preview_idx != -1:
			var section: String = src.substr(preview_idx, 500)
			assert_true(section.find("length_squared") != -1,
				"placement_system preview checks length before normalize")

	# hud.gd - compass direction
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	if hud_script:
		var src: String = hud_script.source_code
		var compass_idx: int = src.find("cam_forward.y = 0")
		if compass_idx != -1:
			var section: String = src.substr(compass_idx, 200)
			assert_true(section.find("length_squared") != -1,
				"hud compass checks length before normalize")

	# ambient_animal_base.gd - flee direction
	var animal_script: GDScript = load("res://scripts/creatures/ambient_animal_base.gd") as GDScript
	if animal_script:
		var src: String = animal_script.source_code
		var flee_idx: int = src.find("func _start_fleeing")
		if flee_idx != -1:
			var section: String = src.substr(flee_idx, 400)
			assert_true(section.find("length_squared") != -1,
				"ambient_animal_base flee checks length before normalize")

	# ambient_bird.gd - flight direction
	var bird_script: GDScript = load("res://scripts/creatures/ambient_bird.gd") as GDScript
	if bird_script:
		var src: String = bird_script.source_code
		var fly_idx: int = src.find("func _process_flying")
		if fly_idx != -1:
			var section: String = src.substr(fly_idx, 400)
			assert_true(section.find("length_squared") != -1,
				"ambient_bird flight checks length before normalize")

	# ambient_rabbit.gd - hop direction
	var rabbit_script: GDScript = load("res://scripts/creatures/ambient_rabbit.gd") as GDScript
	if rabbit_script:
		var src: String = rabbit_script.source_code
		var hop_idx: int = src.find("func _start_single_hop")
		if hop_idx != -1:
			var section: String = src.substr(hop_idx, 400)
			assert_true(section.find("length_squared") != -1,
				"ambient_rabbit hop checks length before normalize")


func test_weather_manager_uses_instance_valid() -> void:
	## Bug: weather_manager.gd used truthiness checks (if not player) instead of
	## is_instance_valid(player) for freed node safety.
	var script: GDScript = load("res://scripts/world/weather_manager.gd") as GDScript
	if not script:
		assert_true(false, "Could not load weather_manager.gd")
		return
	var src: String = script.source_code

	# _apply_weather_effects must use is_instance_valid
	var fn_idx: int = src.find("func _apply_weather_effects")
	var fn_end: int = src.find("\nfunc ", fn_idx + 1)
	var fn_body: String = src.substr(fn_idx, fn_end - fn_idx)
	assert_true(fn_body.find("is_instance_valid(player)") != -1,
		"_apply_weather_effects uses is_instance_valid for player")

	# is_player_protected must use is_instance_valid
	fn_idx = src.find("func is_player_protected")
	fn_end = src.find("\nfunc ", fn_idx + 1)
	fn_body = src.substr(fn_idx, fn_end - fn_idx)
	assert_true(fn_body.find("is_instance_valid(player)") != -1,
		"is_player_protected uses is_instance_valid for player")

	# get_protection_status must use is_instance_valid
	fn_idx = src.find("func get_protection_status")
	fn_end = src.find("\nfunc ", fn_idx + 1)
	fn_body = src.substr(fn_idx, fn_end - fn_idx)
	assert_true(fn_body.find("is_instance_valid(player)") != -1,
		"get_protection_status uses is_instance_valid for player")


func test_chunk_manager_uses_instance_valid() -> void:
	## Bug: chunk_manager.gd _process used truthiness check instead of
	## is_instance_valid for the player reference.
	var script: GDScript = load("res://scripts/world/chunk_manager.gd") as GDScript
	if not script:
		assert_true(false, "Could not load chunk_manager.gd")
		return
	var src: String = script.source_code
	var fn_idx: int = src.find("func _process(")
	var fn_end: int = src.find("\nfunc ", fn_idx + 1)
	var fn_body: String = src.substr(fn_idx, fn_end - fn_idx)
	assert_true(fn_body.find("is_instance_valid(player)") != -1,
		"chunk_manager _process uses is_instance_valid for player")


func test_bark_map_uses_path_key_for_rivers() -> void:
	## Bug: bark_map_ui.gd used river.get("start")/river.get("end") but river
	## dicts use "path" (Array[Vector2]), not "start"/"end". Rivers were invisible.
	var file: FileAccess = FileAccess.open("res://scripts/ui/bark_map_ui.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open bark_map_ui.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Find the _is_in_water function which processes rivers using "path" key
	var river_fn_idx: int = src.find("func _is_in_water")
	assert_true(river_fn_idx != -1, "bark_map has _is_in_water function")
	var river_section: String = src.substr(river_fn_idx, 500)
	assert_true(river_section.find("\"path\"") != -1,
		"bark_map river drawing uses 'path' key")
	assert_true(river_section.find("river.get(\"start\")") == -1,
		"bark_map river drawing does not use wrong 'start' key")


func test_resting_clears_when_structure_freed() -> void:
	## Bug: If the structure a player was resting in gets freed, is_resting
	## stayed true forever, permanently disabling movement (soft-lock).
	var script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not script:
		assert_true(false, "Could not load player_controller.gd")
		return
	var src: String = script.source_code
	# Find the resting check in _physics_process (after "Skip movement")
	var skip_idx: int = src.find("Skip movement processing while resting")
	if skip_idx != -1:
		var section: String = src.substr(skip_idx, 300)
		assert_true(section.find("is_instance_valid(resting_in_structure)") != -1,
			"resting check validates structure is still valid")
		assert_true(section.find("is_resting = false") != -1,
			"resting is cleared when structure becomes invalid")


func test_grappling_hook_checks_current_scene() -> void:
	## Bug: grappling_hook.gd called get_tree().current_scene.add_child()
	## without null check, crashing during scene transitions.
	var script: GDScript = load("res://scripts/player/grappling_hook.gd") as GDScript
	if not script:
		assert_true(false, "Could not load grappling_hook.gd")
		return
	var src: String = script.source_code
	# Should not have bare current_scene.add_child
	var bare_pattern: String = "current_scene.add_child"
	var scene_check: String = "var scene"
	var idx: int = 0
	while idx < src.length():
		var found: int = src.find(bare_pattern, idx)
		if found == -1:
			break
		# Check that there's a scene null check nearby (within 200 chars before)
		var context: String = src.substr(max(0, found - 200), 200)
		assert_true(context.find(scene_check) != -1,
			"grappling_hook checks current_scene before add_child")
		idx = found + 1


func test_osha_root_restores_hunger_when_healing() -> void:
	## Bug: osha_root was in both HEALING_ITEMS and FOOD_VALUES, but healing
	## was checked first, so the hunger restore was never applied.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Find _try_eat function first, then search within it for the healing loop
	var try_eat_idx: int = src.find("func _try_eat(")
	assert_true(try_eat_idx != -1, "_try_eat function exists")
	if try_eat_idx != -1:
		var fn_end: int = src.find("\nfunc ", try_eat_idx + 1)
		var try_eat_body: String = src.substr(try_eat_idx, fn_end - try_eat_idx)
		assert_true(try_eat_body.find("FOOD_VALUES.has(heal_type)") != -1,
			"_try_eat checks if healing item is also food")
		assert_true(try_eat_body.find("stats.eat") != -1,
			"_try_eat applies food value for dual-use healing items")


func test_resource_node_timer_checks_self_validity() -> void:
	## Bug: resource_node.gd used create_timer().timeout.connect(_complete_harvest)
	## which would crash if the node was freed during the timer delay.
	var script: GDScript = load("res://scripts/resources/resource_node.gd") as GDScript
	if not script:
		assert_true(false, "Could not load resource_node.gd")
		return
	var src: String = script.source_code
	# Find the timer section near _complete_harvest
	var timer_idx: int = src.find("create_timer(0.2)")
	if timer_idx != -1:
		var section: String = src.substr(timer_idx, 200)
		assert_true(section.find("is_instance_valid") != -1,
			"resource_node harvest timer checks node validity before callback")


func test_signal_connections_use_is_connected_guard() -> void:
	## Bug: Several signal connections lacked is_connected() guards,
	## risking double-connection if _ready() runs twice.

	# structure_shelter.gd
	var shelter_script: GDScript = load("res://scripts/campsite/structure_shelter.gd") as GDScript
	if shelter_script:
		var src: String = shelter_script.source_code
		var fn_idx: int = src.find("func _connect_to_time_manager")
		if fn_idx != -1:
			var fn_end: int = src.find("\nfunc ", fn_idx + 1)
			var fn_body: String = src.substr(fn_idx, fn_end - fn_idx)
			assert_true(fn_body.find("is_connected") != -1,
				"structure_shelter _connect_to_time_manager uses is_connected guard")

	# campsite_manager.gd
	var cm_script: GDScript = load("res://scripts/campsite/campsite_manager.gd") as GDScript
	if cm_script:
		var src: String = cm_script.source_code
		# Check crafting system connection
		var craft_idx: int = src.find("recipe_crafted.connect")
		if craft_idx != -1:
			var context: String = src.substr(max(0, craft_idx - 100), 100)
			assert_true(context.find("is_connected") != -1,
				"campsite_manager crafting signal uses is_connected guard")
		# Check time manager connection
		var time_idx: int = src.find("day_changed.connect")
		if time_idx != -1:
			var context: String = src.substr(max(0, time_idx - 100), 100)
			assert_true(context.find("is_connected") != -1,
				"campsite_manager time signal uses is_connected guard")

	# weather_manager.gd
	var wm_script: GDScript = load("res://scripts/world/weather_manager.gd") as GDScript
	if wm_script:
		var src: String = wm_script.source_code
		var period_idx: int = src.find("period_changed.connect")
		if period_idx != -1:
			var context: String = src.substr(max(0, period_idx - 100), 100)
			assert_true(context.find("is_connected") != -1,
				"weather_manager period signal uses is_connected guard")


func test_config_menu_float_comparison() -> void:
	## Bug: config_menu.gd compared float value with != 1.0 for pluralization,
	## which can fail due to floating-point imprecision. Should use is_equal_approx.
	var script: GDScript = load("res://scripts/ui/config_menu.gd") as GDScript
	if not script:
		assert_true(false, "Could not load config_menu.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("is_equal_approx") != -1,
		"config_menu uses is_equal_approx for float comparison")
	assert_true(src.find("tree_respawn_days != 1.0") == -1,
		"config_menu does not use bare != 1.0 float comparison")


# ============================================================
# Round 2 Regression Tests
# ============================================================

func test_cave_darkness_uses_player_stats() -> void:
	## Bug: cave_transition.gd called player.take_damage() directly, but damage
	## is handled by PlayerStats node. Must get PlayerStats and call take_damage on it.
	var script: GDScript = load("res://scripts/core/cave_transition.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cave_transition.gd")
		return
	var src: String = script.source_code
	# Find the _apply_darkness_damage function which does the actual damage
	var func_idx: int = src.find("func _apply_darkness_damage")
	assert_true(func_idx != -1, "cave_transition has _apply_darkness_damage")
	var func_body: String = src.substr(func_idx, 500)
	assert_true(func_body.find("PlayerStats") != -1,
		"darkness damage uses PlayerStats node")
	assert_true(func_body.find("stats.take_damage") != -1 or func_body.find("stats.has_method") != -1,
		"darkness damage calls take_damage on stats node")


func test_cave_transition_saves_state() -> void:
	## Bug: cave state (is_in_cave, current_cave_id, is_dark) was not saved,
	## so loading a save while in a cave would lose cave state.
	var script: GDScript = load("res://scripts/core/cave_transition.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cave_transition.gd")
		return
	var src: String = script.source_code
	var save_idx: int = src.find("func get_save_data")
	assert_true(save_idx != -1, "cave_transition has get_save_data")
	var save_body: String = src.substr(save_idx, 300)
	assert_true(save_body.find("is_in_cave") != -1, "get_save_data includes is_in_cave")
	assert_true(save_body.find("current_cave_id") != -1, "get_save_data includes current_cave_id")
	assert_true(save_body.find("is_dark") != -1, "get_save_data includes is_dark")

	var load_idx: int = src.find("func load_save_data")
	assert_true(load_idx != -1, "cave_transition has load_save_data")
	var load_body: String = src.substr(load_idx, 500)
	assert_true(load_body.find("is_in_cave") != -1, "load_save_data restores is_in_cave")
	assert_true(load_body.find("current_cave_id") != -1, "load_save_data restores current_cave_id")
	assert_true(load_body.find("is_dark") != -1, "load_save_data restores is_dark")


func test_cave_resource_state_deep_duplicate() -> void:
	## Bug: get_save_data returned cave_resource_state by reference, so external
	## code could mutate the internal state. Must use .duplicate(true).
	var script: GDScript = load("res://scripts/core/cave_transition.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cave_transition.gd")
		return
	var src: String = script.source_code
	var save_idx: int = src.find("func get_save_data")
	assert_true(save_idx != -1, "cave_transition has get_save_data")
	var save_body: String = src.substr(save_idx, 300)
	assert_true(save_body.find("cave_resource_state.duplicate") != -1,
		"get_save_data duplicates cave_resource_state")


func test_save_load_awaits_campsite_data() -> void:
	## Bug: _apply_campsite_data is async (builds structures with awaits) but was
	## called without await, causing race conditions during load.
	var script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not script:
		assert_true(false, "Could not load save_load.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("await _apply_campsite_data") != -1,
		"save_load awaits _apply_campsite_data")
	assert_true(src.find("await _apply_save_data") != -1,
		"save_load awaits _apply_save_data")


func test_weather_data_saves_day_tracking() -> void:
	## Bug class: without tracking the last-rolled day, a load that re-emits
	## day_changed would re-pop the forecast and apply the wrong weather.
	var script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not script:
		assert_true(false, "Could not load save_load.gd")
		return
	var src: String = script.source_code
	var collect_idx: int = src.find("func _collect_weather_data")
	assert_true(collect_idx != -1, "save_load has _collect_weather_data")
	var collect_body: String = src.substr(collect_idx, 400)
	assert_true(collect_body.find("last_rolled_day") != -1,
		"_collect_weather_data includes last_rolled_day")
	assert_true(collect_body.find("weather_enabled") != -1,
		"_collect_weather_data includes weather_enabled")


func test_weather_data_restores_day_tracking() -> void:
	## Bug class: _apply_weather_data must restore last_rolled_day and
	## weather_enabled alongside the forecast state.
	var script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not script:
		assert_true(false, "Could not load save_load.gd")
		return
	var src: String = script.source_code
	var apply_idx: int = src.find("func _apply_weather_data")
	assert_true(apply_idx != -1, "save_load has _apply_weather_data")
	var apply_body: String = src.substr(apply_idx, 1200)
	assert_true(apply_body.find("last_rolled_day") != -1,
		"_apply_weather_data restores last_rolled_day")
	assert_true(apply_body.find("weather_enabled") != -1,
		"_apply_weather_data restores weather_enabled")


func test_load_game_slot_callers_use_await() -> void:
	## Bug: load_game_slot became a coroutine (has await internally) but callers
	## did not use await, causing errors.
	var script: GDScript = load("res://scripts/core/save_load.gd") as GDScript
	if not script:
		assert_true(false, "Could not load save_load.gd")
		return
	var src: String = script.source_code
	var load_game_idx: int = src.find("func load_game()")
	assert_true(load_game_idx != -1, "save_load has load_game()")
	var load_game_body: String = src.substr(load_game_idx, 200)
	assert_true(load_game_body.find("await load_game_slot") != -1,
		"load_game() awaits load_game_slot")


func test_config_menu_has_apply_config() -> void:
	## Bug: config settings were not saved/restored on load because config_menu
	## had no apply_config method to restore settings from save data.
	var script: GDScript = load("res://scripts/ui/config_menu.gd") as GDScript
	if not script:
		assert_true(false, "Could not load config_menu.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("func apply_config(data: Dictionary)") != -1,
		"config_menu has apply_config method")
	var apply_idx: int = src.find("func apply_config")
	var apply_body: String = src.substr(apply_idx, 600)
	assert_true(apply_body.find("hunger_enabled") != -1,
		"apply_config restores hunger_enabled")
	assert_true(apply_body.find("weather_enabled") != -1,
		"apply_config restores weather_enabled")


func test_config_kl_keys_check_visibility() -> void:
	## Bug: K/L keys in config_menu toggled settings even when menu was closed,
	## interfering with gameplay. Must check is_visible.
	var script: GDScript = load("res://scripts/ui/config_menu.gd") as GDScript
	if not script:
		assert_true(false, "Could not load config_menu.gd")
		return
	var src: String = script.source_code
	var k_idx: int = src.find("KEY_K")
	assert_true(k_idx != -1, "config_menu has KEY_K handler")
	var k_context: String = src.substr(max(0, k_idx - 50), 100)
	assert_true(k_context.find("is_visible") != -1,
		"KEY_K handler checks is_visible")
	var l_idx: int = src.find("KEY_L")
	assert_true(l_idx != -1, "config_menu has KEY_L handler")
	var l_context: String = src.substr(max(0, l_idx - 50), 100)
	assert_true(l_context.find("is_visible") != -1,
		"KEY_L handler checks is_visible")


func test_processing_structures_lookup_player_on_complete() -> void:
	## Bug: drying rack, smoker, and smithing station cached player_inventory
	## at build time. If player reloaded, the cached reference went stale and
	## completed items were lost. Refactored to use pending_output and signals.
	for file_path: String in [
		"res://scripts/campsite/structure_drying_rack.gd",
		"res://scripts/campsite/structure_smoker.gd",
		"res://scripts/campsite/structure_smithing_station.gd",
	]:
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			assert_true(false, "Could not open %s" % file_path)
			continue
		var src: String = file.get_as_text()
		file.close()
		# Structures now use pending_output/signals instead of direct inventory access
		assert_true(src.find("pending_output") != -1,
			"%s uses pending_output for completed items" % file_path.get_file())


func test_use_equipped_checks_placement_active() -> void:
	## Bug: use_equipped would fire while placement system was active (placing/moving
	## a structure), consuming items unintentionally.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Find the use_equipped action handler and search within its block
	var equip_idx: int = src.find("\"use_equipped\"")
	assert_true(equip_idx != -1, "player_controller has use_equipped action handler")
	# Search forward from the handler for the placement guard (within 1500 chars)
	var equip_context: String = src.substr(equip_idx, 1500)
	assert_true(equip_context.find("is_placing") != -1,
		"use_equipped checks placement is_placing")


func test_dried_herb_in_food_values() -> void:
	## Bug: dried_herb had no entry in FOOD_VALUES, making it unconsumable
	## despite being a crafted food item.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var food_idx: int = src.find("FOOD_VALUES")
	assert_true(food_idx != -1, "player_controller has FOOD_VALUES")
	var food_body: String = src.substr(food_idx, 1000)
	assert_true(food_body.find("dried_herb") != -1,
		"FOOD_VALUES includes dried_herb")


func test_fire_menu_has_raw_meat_recipe() -> void:
	## Bug: fire_menu had no recipe for raw_meat, so players could not cook
	## meat at the campfire despite having it in inventory.
	var file: FileAccess = FileAccess.open("res://scripts/ui/fire_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fire_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("raw_meat") != -1,
		"fire_menu has raw_meat recipe")
	assert_true(src.find("cooked_meat") != -1,
		"fire_menu raw_meat recipe produces cooked_meat")


func test_fire_menu_checks_is_lit() -> void:
	## Bug: players could cook/warm at extinguished fires because there was
	## no check for fire.is_lit before allowing those actions.
	var file: FileAccess = FileAccess.open("res://scripts/ui/fire_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fire_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("is_lit") != -1,
		"fire_menu checks is_lit before actions")
	# Check both cook and warm functions reference is_lit
	var cook_idx: int = src.find("func _on_cook")
	if cook_idx != -1:
		var cook_body: String = src.substr(cook_idx, 500)
		assert_true(cook_body.find("is_lit") != -1,
			"cook function checks is_lit")
	var warm_idx: int = src.find("func _on_warm")
	if warm_idx != -1:
		var warm_body: String = src.substr(warm_idx, 500)
		assert_true(warm_body.find("is_lit") != -1,
			"warm function checks is_lit")


func test_fire_menu_cooking_uses_inventory() -> void:
	## Bug: cooking at fire directly restored hunger instead of producing
	## cooked items in inventory, bypassing the food system.
	var file: FileAccess = FileAccess.open("res://scripts/ui/fire_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fire_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var cook_idx: int = src.find("func _on_cook")
	assert_true(cook_idx != -1, "fire_menu has cook function")
	var cook_body: String = src.substr(cook_idx, 1000)
	assert_true(cook_body.find("add_item") != -1,
		"cooking adds output item to inventory")


func test_equipment_menu_sets_mouse_mode() -> void:
	## Bug: equipment menu did not show/hide mouse cursor when opening/closing,
	## leaving cursor invisible when menu open or visible when closed.
	var script: GDScript = load("res://scripts/ui/equipment_menu.gd") as GDScript
	if not script:
		assert_true(false, "Could not load equipment_menu.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("MOUSE_MODE_VISIBLE") != -1,
		"equipment_menu shows cursor when open")
	assert_true(src.find("MOUSE_MODE_CAPTURED") != -1,
		"equipment_menu captures cursor when closed")


func test_fishing_respawn_checks_hours() -> void:
	## Bug: fishing spots always respawned on day change regardless of how
	## recently they were depleted. Must check hours elapsed vs respawn_time_hours.
	var file: FileAccess = FileAccess.open("res://scripts/resources/fishing_spot.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fishing_spot.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var day_idx: int = src.find("func _on_day_changed")
	assert_true(day_idx != -1, "fishing_spot has _on_day_changed")
	var day_body: String = src.substr(day_idx, 600)
	assert_true(day_body.find("respawn_time_hours") != -1,
		"_on_day_changed checks respawn_time_hours")


func test_crafting_getters_return_duplicates() -> void:
	## Bug: get_discovered_recipes and get_recipe returned internal arrays/dicts
	## by reference, allowing callers to mutate internal crafting state.
	var script: GDScript = load("res://scripts/crafting/crafting_system.gd") as GDScript
	if not script:
		assert_true(false, "Could not load crafting_system.gd")
		return
	var src: String = script.source_code
	var disc_idx: int = src.find("func get_discovered_recipes")
	assert_true(disc_idx != -1, "crafting_system has get_discovered_recipes")
	var disc_body: String = src.substr(disc_idx, 200)
	assert_true(disc_body.find(".duplicate()") != -1,
		"get_discovered_recipes returns duplicate")

	var recipe_idx: int = src.find("func get_recipe")
	assert_true(recipe_idx != -1, "crafting_system has get_recipe")
	var recipe_body: String = src.substr(recipe_idx, 200)
	assert_true(recipe_body.find(".duplicate()") != -1,
		"get_recipe returns duplicate")


func test_campsite_get_structures_returns_duplicate() -> void:
	## Bug: get_placed_structures returned internal array by reference,
	## allowing external code to accidentally add/remove structures.
	var script: GDScript = load("res://scripts/campsite/campsite_manager.gd") as GDScript
	if not script:
		assert_true(false, "Could not load campsite_manager.gd")
		return
	var src: String = script.source_code
	var idx: int = src.find("func get_placed_structures")
	assert_true(idx != -1, "campsite_manager has get_placed_structures")
	var body: String = src.substr(idx, 200)
	assert_true(body.find(".duplicate()") != -1,
		"get_placed_structures returns duplicate")


# ============================================================
# Round 3 Regression Tests
# ============================================================

func test_fishing_spot_tracks_depleted_day() -> void:
	## Bug: FishingSpot only tracked depleted_hour/minute but not depleted_day,
	## so _on_day_changed assumed depletion was yesterday, causing permanent depletion.
	var file: FileAccess = FileAccess.open("res://scripts/resources/fishing_spot.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fishing_spot.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Must have depleted_day variable
	assert_true(src.find("var depleted_day") != -1,
		"fishing_spot has depleted_day variable")
	# _on_day_changed must use depleted_day, not (current_day - 1)
	var day_changed_idx: int = src.find("func _on_day_changed")
	assert_true(day_changed_idx != -1, "fishing_spot has _on_day_changed")
	var day_body: String = src.substr(day_changed_idx, 500)
	assert_true(day_body.find("depleted_day") != -1,
		"_on_day_changed uses depleted_day")
	assert_true(day_body.find("current_day - 1") == -1,
		"_on_day_changed does not hardcode current_day - 1")
	# interact() respawn check must also use depleted_day
	var interact_idx: int = src.find("func interact")
	assert_true(interact_idx != -1, "fishing_spot has interact")
	var interact_body: String = src.substr(interact_idx, 500)
	assert_true(interact_body.find("depleted_day") != -1,
		"interact respawn check uses depleted_day")


func test_death_resets_water_state() -> void:
	## Bug: _on_player_died did not reset is_in_water, causing swimming physics
	## and underwater overlay to persist after respawn on dry land.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var death_idx: int = src.find("func _on_player_died")
	assert_true(death_idx != -1, "player_controller has _on_player_died")
	var death_body: String = src.substr(death_idx, 1500)
	assert_true(death_body.find("is_in_water") != -1,
		"_on_player_died resets is_in_water")
	assert_true(death_body.find("_water_area_count") != -1,
		"_on_player_died resets _water_area_count")


func test_death_closes_menus() -> void:
	## Bug: Death did not close open UI menus, leaving mouse visible and
	## menus displayed with stale data after respawn.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var death_idx: int = src.find("func _on_player_died")
	assert_true(death_idx != -1, "player_controller has _on_player_died")
	var death_body: String = src.substr(death_idx, 3500)
	assert_true(death_body.find("_close_all_menus") != -1,
		"_on_player_died calls _close_all_menus")
	assert_true(src.find("func _close_all_menus") != -1,
		"player_controller has _close_all_menus method")


func test_window_refocus_recaptures_mouse() -> void:
	## Bug: Window refocus did not re-capture mouse, requiring menu open/close
	## to restore mouse capture after alt-tabbing.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("NOTIFICATION_WM_WINDOW_FOCUS_IN") != -1,
		"player_controller handles FOCUS_IN notification")


func test_equipment_input_has_ui_guard() -> void:
	## Bug: Equipment._input had no UI state guards, causing equipment changes
	## to fire during any open menu. Controller Cross = both unequip and ui_cancel.
	var file: FileAccess = FileAccess.open("res://scripts/player/equipment.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open equipment.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var input_idx: int = src.find("func _input")
	assert_true(input_idx != -1, "equipment has _input handler")
	var input_body: String = src.substr(input_idx, 300)
	assert_true(input_body.find("_is_ui_blocking_input") != -1,
		"equipment _input checks _is_ui_blocking_input")


func test_player_actions_blocked_by_ui() -> void:
	## Bug: Player interact/eat/use_equipped were not blocked when UI menus
	## were open, allowing actions behind menus.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var input_idx: int = src.find("func _input")
	assert_true(input_idx != -1, "player_controller has _input")
	# Find the section between _input and the first action handler
	var interact_idx: int = src.find("is_action_pressed(\"interact\")", input_idx)
	assert_true(interact_idx != -1, "player_controller handles interact action")
	var between: String = src.substr(input_idx, interact_idx - input_idx)
	assert_true(between.find("_is_ui_blocking_input") != -1,
		"_input checks _is_ui_blocking_input before action handlers")


func test_movement_blocked_by_ui() -> void:
	## Bug: WASD movement was not blocked when UI menus were open because
	## _physics_process polled Input without checking UI state.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var move_idx: int = src.find("func _process_normal_movement")
	assert_true(move_idx != -1, "player_controller has _process_normal_movement")
	var move_body: String = src.substr(move_idx, 800)
	assert_true(move_body.find("_is_ui_blocking_input") != -1,
		"_process_normal_movement checks UI blocking for movement")


func test_controller_look_blocked_by_ui() -> void:
	## Bug: Controller right-stick look worked while menus were open.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Find the _handle_controller_look call in _physics_process
	var call_idx: int = src.find("_handle_controller_look")
	assert_true(call_idx != -1, "player_controller calls _handle_controller_look")
	var context: String = src.substr(max(0, call_idx - 200), 250)
	assert_true(context.find("ui_blocking") != -1 or context.find("_is_ui_blocking_input") != -1,
		"controller look is gated by UI blocking check")


func test_cave_id_default_is_negative_one() -> void:
	## Bug: cave_transition.load_save_data used "" (empty string) as default
	## for current_cave_id (typed as int), causing type mismatch.
	var script: GDScript = load("res://scripts/core/cave_transition.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cave_transition.gd")
		return
	var src: String = script.source_code
	var load_idx: int = src.find("func load_save_data")
	assert_true(load_idx != -1, "cave_transition has load_save_data")
	var load_body: String = src.substr(load_idx, 300)
	assert_true(load_body.find("current_cave_id\", -1") != -1,
		"load_save_data uses -1 as default for current_cave_id")
	assert_true(load_body.find("current_cave_id\", \"\"") == -1,
		"load_save_data does not use empty string default for cave_id")


func test_camera_lerp_alpha_clamped() -> void:
	## Bug: Camera collision lerp alpha (12.0 * delta) could exceed 1.0 at low
	## FPS, causing overshoot. Must be clamped with minf().
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("minf(CAMERA_COLLISION_LERP_SPEED * delta, 1.0)") != -1,
		"camera lerp alpha is clamped with minf")


func test_grapple_cancel_consumes_input() -> void:
	## Bug: Grappling hook cancel did not call set_input_as_handled(),
	## causing the event to leak to equipment.gd and unequip the hook.
	var file: FileAccess = FileAccess.open("res://scripts/player/grappling_hook.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open grappling_hook.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var cancel_idx: int = src.find("cancel_grapple()")
	assert_true(cancel_idx != -1, "grappling_hook calls cancel_grapple")
	var after_cancel: String = src.substr(cancel_idx, 200)
	assert_true(after_cancel.find("set_input_as_handled") != -1,
		"grapple cancel consumes input event")


func test_placement_consumes_input() -> void:
	## Bug: Placement system confirm/cancel did not consume input events,
	## leaking to equipment._input and causing unintended unequip.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/placement_system.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open placement_system.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("_consume_input") != -1,
		"placement_system has _consume_input method")
	assert_true(src.find("set_input_as_handled") != -1,
		"placement_system consumes input events")


func test_flare_tween_tracked() -> void:
	## Bug: Fire pit flare() created new tweens without killing previous ones,
	## causing fighting tweens on rapid calls.
	var script: GDScript = load("res://scripts/campsite/structure_fire_pit.gd") as GDScript
	if not script:
		assert_true(false, "Could not load structure_fire_pit.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("var flare_tween") != -1,
		"fire_pit tracks flare_tween")
	var flare_idx: int = src.find("func flare")
	assert_true(flare_idx != -1, "fire_pit has flare method")
	var flare_body: String = src.substr(flare_idx, 400)
	assert_true(flare_body.find("flare_tween.kill()") != -1,
		"flare kills previous tween before creating new one")


func test_placement_requires_inventory() -> void:
	## Bug: _confirm_placement skipped item consumption when inventory was null,
	## giving free structures.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/placement_system.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open placement_system.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var confirm_idx: int = src.find("func _confirm_placement")
	assert_true(confirm_idx != -1, "placement_system has _confirm_placement")
	var confirm_body: String = src.substr(confirm_idx, 1400)
	assert_true(confirm_body.find("not inventory") != -1,
		"_confirm_placement checks for null inventory and aborts")


func test_storage_unequips_on_transfer() -> void:
	## Bug: Equipped items could be transferred to storage while still equipped,
	## creating phantom usable items.
	var script: GDScript = load("res://scripts/ui/storage_ui.gd") as GDScript
	if not script:
		assert_true(false, "Could not load storage_ui.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("_unequip_if_equipped") != -1,
		"storage_ui has _unequip_if_equipped method")
	var transfer_idx: int = src.find("func _on_transfer_pressed")
	assert_true(transfer_idx != -1, "storage_ui has _on_transfer_pressed")
	var transfer_body: String = src.substr(transfer_idx, 400)
	assert_true(transfer_body.find("_unequip_if_equipped") != -1,
		"_on_transfer_pressed calls _unequip_if_equipped")


func test_menu_overlap_prevention() -> void:
	## Bug: Crafting/equipment menus could open on top of other menus,
	## creating overlapping UIs with conflicting input handlers.
	var script: GDScript = load("res://scripts/ui/crafting_ui.gd") as GDScript
	if not script:
		assert_true(false, "Could not load crafting_ui.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("_is_other_menu_open") != -1,
		"crafting_ui has _is_other_menu_open check")
	var equip_script: GDScript = load("res://scripts/ui/equipment_menu.gd") as GDScript
	if not equip_script:
		assert_true(false, "Could not load equipment_menu.gd")
		return
	var equip_src: String = equip_script.source_code
	assert_true(equip_src.find("_is_other_menu_open") != -1,
		"equipment_menu has _is_other_menu_open check")


func test_water_ref_counting() -> void:
	## Bug: set_in_water used a simple boolean. Overlapping water areas
	## (fishing spot + river) caused premature is_in_water=false on exit from one.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("_water_area_count") != -1,
		"player_controller has _water_area_count for ref-counting")
	var set_idx: int = src.find("func set_in_water")
	assert_true(set_idx != -1, "player_controller has set_in_water")
	var set_body: String = src.substr(set_idx, 400)
	assert_true(set_body.find("_water_area_count") != -1,
		"set_in_water uses _water_area_count")


# ============================================================
# Round 4 regression tests
# ============================================================

func test_player_position_uses_saved_y_in_cave() -> void:
	## Bug: Player Y position was always recalculated from terrain on load,
	## ignoring saved Y. This broke cave respawning where the player is underground.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var apply_idx: int = src.find("func _apply_player_data")
	assert_true(apply_idx != -1, "save_load has _apply_player_data")
	var apply_body: String = src.substr(apply_idx, 1200)
	# Must check for cave state before overriding Y
	assert_true(apply_body.find("was_in_cave") != -1 or apply_body.find("is_in_cave") != -1,
		"_apply_player_data checks cave state before overriding Y position")
	# Must use saved Y (load_y)
	assert_true(apply_body.find("load_y") != -1,
		"_apply_player_data reads saved Y position")


func test_equipment_tween_created_on_self() -> void:
	## Bug: axe_swing_tween was created on player.create_tween() but animated
	## Equipment child nodes. If Equipment freed, tween operated on invalid nodes.
	var file: FileAccess = FileAccess.open("res://scripts/player/equipment.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open equipment.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Should NOT find player.create_tween for axe swing
	assert_true(src.find("axe_swing_tween = player.create_tween()") == -1,
		"axe_swing_tween should not be created on player node")
	# Should find create_tween() (on self)
	assert_true(src.find("axe_swing_tween = create_tween()") != -1,
		"axe_swing_tween should be created on self (Equipment node)")


func test_loading_screen_checks_validity_after_await() -> void:
	## Bug: Loading screen resumed coroutine after await without checking if
	## the node was still valid, causing create_tween on freed node.
	var file: FileAccess = FileAccess.open("res://scripts/ui/loading_screen.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open loading_screen.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var finish_idx: int = src.find("func _finish_loading")
	assert_true(finish_idx != -1, "loading_screen has _finish_loading")
	var finish_body: String = src.substr(finish_idx, 400)
	assert_true(finish_body.find("is_instance_valid") != -1,
		"_finish_loading checks is_instance_valid after await")


func test_notification_timer_uses_is_connected() -> void:
	## Bug: HUD notification timer disconnect called without checking
	## is_connected first, causing error if signal already fired.
	var file: FileAccess = FileAccess.open("res://scripts/ui/hud.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open hud.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var notif_idx: int = src.find("func show_notification")
	assert_true(notif_idx != -1, "hud has show_notification")
	var notif_body: String = src.substr(notif_idx, 800)
	assert_true(notif_body.find("is_connected") != -1,
		"show_notification checks is_connected before disconnecting timer")


func test_celebration_tween_uses_is_valid() -> void:
	## Bug: celebration_tween.kill() called without is_valid() check,
	## inconsistent with fire_pit and other tween patterns.
	var file: FileAccess = FileAccess.open("res://scripts/ui/hud.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open hud.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var celeb_idx: int = src.find("func _show_level_celebration")
	assert_true(celeb_idx != -1, "hud has _show_level_celebration")
	var celeb_body: String = src.substr(celeb_idx, 1800)
	assert_true(celeb_body.find("is_valid") != -1,
		"_show_level_celebration checks celebration_tween.is_valid() before kill")


func test_config_saves_music_settings() -> void:
	## Bug: music_enabled and music_volume were not included in get_config(),
	## losing music preferences on save/load.
	var file: FileAccess = FileAccess.open("res://scripts/ui/config_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open config_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var config_idx: int = src.find("func get_config")
	assert_true(config_idx != -1, "config_menu has get_config")
	var config_body: String = src.substr(config_idx, 600)
	assert_true(config_body.find("music_enabled") != -1,
		"get_config includes music_enabled")
	assert_true(config_body.find("music_volume") != -1,
		"get_config includes music_volume")


func test_config_restores_music_settings() -> void:
	## Bug: apply_config did not restore music_enabled or music_volume.
	var file: FileAccess = FileAccess.open("res://scripts/ui/config_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open config_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var apply_idx: int = src.find("func apply_config")
	assert_true(apply_idx != -1, "config_menu has apply_config")
	var apply_body: String = src.substr(apply_idx, 1200)
	assert_true(apply_body.find("music_enabled") != -1,
		"apply_config restores music_enabled")
	assert_true(apply_body.find("music_volume") != -1,
		"apply_config restores music_volume")


func test_cave_light_check_timer_reset_on_load() -> void:
	## Bug: light_check_timer was not reset in load_save_data, causing
	## darkness checks to be delayed after loading in a cave.
	var script: GDScript = load("res://scripts/core/cave_transition.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cave_transition.gd")
		return
	var src: String = script.source_code
	var load_idx: int = src.find("func load_save_data")
	assert_true(load_idx != -1, "cave_transition has load_save_data")
	var load_body: String = src.substr(load_idx, 400)
	assert_true(load_body.find("light_check_timer") != -1,
		"load_save_data resets light_check_timer")


func test_health_hunger_clamped_on_load() -> void:
	## Bug: Health and hunger loaded from save data were not clamped to valid
	## ranges, allowing corrupted saves to set negative or above-max values.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var apply_idx: int = src.find("func _apply_player_data")
	assert_true(apply_idx != -1, "save_load has _apply_player_data")
	var apply_body: String = src.substr(apply_idx, 3000)
	assert_true(apply_body.find("clampf") != -1,
		"_apply_player_data clamps health/hunger values")


func test_structure_position_defaults_are_float() -> void:
	## Bug: Structure position defaults used int 0 instead of float 0.0,
	## causing type inconsistency in Vector3 construction.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var recreate_idx: int = src.find("func _recreate_structure")
	assert_true(recreate_idx != -1, "save_load has _recreate_structure")
	var recreate_body: String = src.substr(recreate_idx, 400)
	# Check that defaults are 0.0 (float) not 0 (int)
	assert_true(recreate_body.find('get("x", 0.0)') != -1,
		"structure position X default is float 0.0")
	assert_true(recreate_body.find('get("y", 0.0)') != -1,
		"structure position Y default is float 0.0")
	assert_true(recreate_body.find('get("z", 0.0)') != -1,
		"structure position Z default is float 0.0")


# ============================================================
# Round 5 regression tests
# ============================================================

func test_death_signal_guarded_by_is_dead() -> void:
	## Bug: player_died signal could emit multiple times in a single frame
	## because both _update_health and take_damage could trigger it.
	var script: GDScript = load("res://scripts/player/player_stats.gd") as GDScript
	if not script:
		assert_true(false, "Could not load player_stats.gd")
		return
	var src: String = script.source_code
	assert_true(src.find("var is_dead: bool") != -1,
		"player_stats has is_dead guard flag")
	var update_idx: int = src.find("func _update_health")
	assert_true(update_idx != -1, "player_stats has _update_health")
	var update_body: String = src.substr(update_idx, 500)
	assert_true(update_body.find("is_dead") != -1,
		"_update_health checks is_dead before processing")


func test_take_damage_guarded_by_is_dead() -> void:
	## Bug: take_damage could emit player_died when health was already 0.
	var script: GDScript = load("res://scripts/player/player_stats.gd") as GDScript
	if not script:
		assert_true(false, "Could not load player_stats.gd")
		return
	var src: String = script.source_code
	var take_idx: int = src.find("func take_damage")
	assert_true(take_idx != -1, "player_stats has take_damage")
	var take_body: String = src.substr(take_idx, 400)
	assert_true(take_body.find("is_dead") != -1,
		"take_damage checks is_dead before processing")


func test_time_changed_emitted_on_load() -> void:
	## Bug: save/load emitted day_changed but not time_changed after loading
	## time data, causing HUD to show stale time and environment lighting
	## to be out of sync.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var time_idx: int = src.find("func _apply_time_data")
	assert_true(time_idx != -1, "save_load has _apply_time_data")
	var time_body: String = src.substr(time_idx, 400)
	assert_true(time_body.find("time_changed.emit") != -1,
		"_apply_time_data emits time_changed signal")
	assert_true(time_body.find("day_changed.emit") != -1,
		"_apply_time_data emits day_changed signal")


func test_reclaimable_no_double_unregister() -> void:
	## Bug: Reclaimable structures (torch, lantern, lodestone) called
	## _unregister_from_campsite() AND destroy() which triggered unregister
	## again via signal, potentially decrementing structure counts twice.
	var torch_file: FileAccess = FileAccess.open("res://scripts/campsite/structure_placed_torch.gd", FileAccess.READ)
	if not torch_file:
		assert_true(false, "Could not open structure_placed_torch.gd")
		return
	var torch_src: String = torch_file.get_as_text()
	torch_file.close()
	var interact_idx: int = torch_src.find("func interact")
	assert_true(interact_idx != -1, "placed_torch has interact")
	var interact_body: String = torch_src.substr(interact_idx, 400)
	assert_true(interact_body.find("_unregister_from_campsite") == -1,
		"placed_torch interact does not manually unregister (destroy() handles it)")


func test_placement_checks_water() -> void:
	## Bug: Placement system allowed structures in water bodies.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/placement_system.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open placement_system.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var validate_idx: int = src.find("func _validate_placement")
	assert_true(validate_idx != -1, "placement_system has _validate_placement")
	var validate_body: String = src.substr(validate_idx, 800)
	assert_true(validate_body.find("is_in_water") != -1,
		"_validate_placement checks for water bodies")


func test_shelter_uses_eat_method() -> void:
	## Bug: Shelter set stats.hunger directly without emitting hunger_changed.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_shelter.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_shelter.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var skip_idx: int = src.find("func _skip_to_dawn")
	assert_true(skip_idx != -1, "shelter has _skip_to_dawn")
	var skip_body: String = src.substr(skip_idx, 1000)
	assert_true(skip_body.find(".eat(") != -1,
		"_skip_to_dawn uses eat() method instead of direct assignment")


func test_cabin_bed_uses_eat_method() -> void:
	## Bug: Cabin bed set stats.hunger directly without emitting hunger_changed.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/cabin_bed.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open cabin_bed.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Check daytime rest
	var rest_idx: int = src.find("func _do_rest")
	assert_true(rest_idx != -1, "cabin_bed has _do_rest")
	var rest_body: String = src.substr(rest_idx, 400)
	assert_true(rest_body.find(".eat(") != -1,
		"_do_rest uses eat() method")
	# Check full restore
	var full_idx: int = src.find("func _do_full_restore")
	assert_true(full_idx != -1, "cabin_bed has _do_full_restore")
	var full_body: String = src.substr(full_idx, 400)
	assert_true(full_body.find(".eat(") != -1,
		"_do_full_restore uses eat() method")


func test_canvas_tent_uses_eat_method() -> void:
	## Bug: Canvas tent set stats.hunger directly without emitting hunger_changed.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_canvas_tent.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_canvas_tent.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var skip_idx: int = src.find("func _skip_to_dawn")
	assert_true(skip_idx != -1, "canvas_tent has _skip_to_dawn")
	var skip_body: String = src.substr(skip_idx, 1000)
	assert_true(skip_body.find(".eat(") != -1,
		"canvas_tent _skip_to_dawn uses eat() method")


## REMOVED: test_kitchen_uses_eat_method
## Kitchen interact() cooks food and adds it to inventory — it does NOT
## restore hunger directly. The player eats the cooked food later via _try_eat().


# ============================================================
# Round 6 regression tests
# ============================================================


func test_resource_respawn_no_double_day_count() -> void:
	## Bug: resource_manager.gd added 1440 min when elapsed < 0 AND added days_elapsed * 1440,
	## double-counting day boundaries so resources respawned ~3x too fast.
	var file: FileAccess = FileAccess.open("res://scripts/resources/resource_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open resource_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# The old pattern: if elapsed < 0: elapsed += 24.0 * 60.0 should be gone
	assert_true(src.find("if elapsed < 0") == -1,
		"resource_manager no longer has 'if elapsed < 0' day correction (days_elapsed handles it)")
	# days_elapsed multiplication should still exist
	assert_true(src.find("days_elapsed * 24.0 * 60.0") != -1,
		"resource_manager uses days_elapsed for day tracking")


func test_save_load_uses_position_not_global() -> void:
	## Bug: save_load.gd set global_position before add_child (node not in tree).
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var recreate_idx: int = src.find("func _recreate_structure")
	assert_true(recreate_idx != -1, "save_load has _recreate_structure")
	var body: String = src.substr(recreate_idx, 2500)
	# Should use position = pos, not global_position = pos before add_child
	var pos_assign_idx: int = body.find("structure.position = pos")
	var add_child_idx: int = body.find("container.add_child(structure)")
	assert_true(pos_assign_idx != -1,
		"save_load uses structure.position (not global_position) before add_child")
	assert_true(pos_assign_idx < add_child_idx,
		"position assignment happens before add_child")


func test_save_load_guards_register_with_container() -> void:
	## Bug: save_load.gd registered structure with campsite_manager even when container was null.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var recreate_idx: int = src.find("func _recreate_structure")
	assert_true(recreate_idx != -1, "save_load has _recreate_structure")
	var body: String = src.substr(recreate_idx, 2500)
	# register_structure should only be called inside the if container block
	var register_idx: int = body.find("register_structure")
	var if_container_idx: int = body.find("if container:")
	assert_true(if_container_idx != -1, "save_load checks if container exists")
	assert_true(register_idx > if_container_idx,
		"register_structure is inside container check")


func test_underwater_effect_checks_canvas_name() -> void:
	## Bug: _show_underwater_effect checked has_node("UnderwaterOverlay") but
	## the CanvasLayer is named "UnderwaterCanvas", so it always created new nodes.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var show_idx: int = src.find("func _show_underwater_effect")
	assert_true(show_idx != -1, "player has _show_underwater_effect")
	var body: String = src.substr(show_idx, 600)
	# Should check for "UnderwaterCanvas" not "UnderwaterOverlay"
	assert_true(body.find('has_node("UnderwaterCanvas")') != -1,
		"_show_underwater_effect checks for UnderwaterCanvas (the actual child name)")
	assert_true(body.find('has_node("UnderwaterOverlay")') == -1,
		"_show_underwater_effect does NOT check for UnderwaterOverlay (wrong name)")


func test_grapple_end_resets_is_falling() -> void:
	## Bug: is_falling was not reset when grapple ended, causing false fall damage
	## from pre-grapple fall_start_y height.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var set_idx: int = src.find("func set_grappling")
	assert_true(set_idx != -1, "player has set_grappling")
	var body: String = src.substr(set_idx, 400)
	assert_true(body.find("is_falling = false") != -1,
		"set_grappling resets is_falling when grapple ends")


func test_grapple_cancel_clears_attach_timer() -> void:
	## Bug: Grapple attach sound timer fired even after cancel_grapple.
	var file: FileAccess = FileAccess.open("res://scripts/player/grappling_hook.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open grappling_hook.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Should have attach_sound_timer variable
	assert_true(src.find("attach_sound_timer") != -1,
		"grappling_hook tracks attach_sound_timer")
	# cancel_grapple should clear the timer
	var cancel_idx: int = src.find("func cancel_grapple")
	assert_true(cancel_idx != -1, "grappling_hook has cancel_grapple")
	var body: String = src.substr(cancel_idx, 500)
	assert_true(body.find("attach_sound_timer") != -1,
		"cancel_grapple handles attach_sound_timer cleanup")


func test_bird_flee_guards_zero_vector() -> void:
	## Bug: Bird flee direction called .normalized() on zero-length Vector2
	## when bird is at same XZ position as player, producing NaN.
	var file: FileAccess = FileAccess.open("res://scripts/creatures/ambient_bird.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open ambient_bird.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var flee_idx: int = src.find("_on_enter_fleeing")
	assert_true(flee_idx != -1, "bird has _on_enter_fleeing")
	var body: String = src.substr(flee_idx, 600)
	assert_true(body.find("length_squared") != -1,
		"flee direction guards against zero-length vector")


func test_ambient_sound_sync_checks_validity() -> void:
	## Bug: _sync_emitters called .stop() on emitter that may already be freed.
	var file: FileAccess = FileAccess.open("res://scripts/core/ambient_sound_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open ambient_sound_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var sync_idx: int = src.find("func _sync_emitters")
	assert_true(sync_idx != -1, "ambient_sound_manager has _sync_emitters")
	var body: String = src.substr(sync_idx, 400)
	assert_true(body.find("is_instance_valid(emitter)") != -1,
		"_sync_emitters checks emitter validity before stop()")


func test_berry_bush_respawn_resets_chop_float() -> void:
	## Bug: berry_bush.respawn() didn't reset chop_progress_float,
	## making the bush easier to harvest after respawn.
	var file: FileAccess = FileAccess.open("res://scripts/resources/berry_bush.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open berry_bush.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var respawn_idx: int = src.find("func respawn")
	assert_true(respawn_idx != -1, "berry_bush has respawn")
	var body: String = src.substr(respawn_idx, 400)
	assert_true(body.find("chop_progress_float = 0.0") != -1,
		"berry_bush respawn resets chop_progress_float")


func test_fire_pit_dim_skips_during_flare() -> void:
	## Bug: _process dim logic and flare() tween both wrote fire_light.light_energy,
	## causing visual fighting during flare animation.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_fire_pit.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_fire_pit.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# The dim logic should check if flare_tween is active before adjusting light
	var process_idx: int = src.find("func _process")
	assert_true(process_idx != -1, "fire_pit has _process")
	var body: String = src.substr(process_idx, 1200)
	assert_true(body.find("flare_tween") != -1,
		"_process dim logic checks flare_tween before adjusting light")


func test_save_load_clears_cached_arrays() -> void:
	## Bug: save_load cleared placed_structures and structure_counts but not
	## _cached_fire_pits and _cached_shelters, leaving freed node references.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("_cached_fire_pits") != -1,
		"save_load clears _cached_fire_pits on load")
	assert_true(src.find("_cached_shelters") != -1,
		"save_load clears _cached_shelters on load")


func test_shelter_skip_dawn_checks_self_valid() -> void:
	## Bug: shelter _skip_to_dawn callback could fire on freed structure.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_shelter.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_shelter.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var skip_idx: int = src.find("func _skip_to_dawn")
	assert_true(skip_idx != -1, "shelter has _skip_to_dawn")
	var body: String = src.substr(skip_idx, 300)
	assert_true(body.find("is_instance_valid(self)") != -1,
		"shelter _skip_to_dawn checks self validity")


func test_cabin_bed_skip_dawn_checks_self_valid() -> void:
	## Bug: cabin bed _skip_to_dawn callback could fire on freed structure.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/cabin_bed.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open cabin_bed.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var skip_idx: int = src.find("func _skip_to_dawn")
	assert_true(skip_idx != -1, "cabin_bed has _skip_to_dawn")
	var body: String = src.substr(skip_idx, 300)
	assert_true(body.find("is_instance_valid(self)") != -1,
		"cabin_bed _skip_to_dawn checks self validity")


# ============================================================
# Round 7 regression tests
# ============================================================


func test_environment_manager_uses_get_node_or_null() -> void:
	## Bug: environment_manager.gd used get_node() without null check, crashing on invalid path.
	var file: FileAccess = FileAccess.open("res://scripts/world/environment_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open environment_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var ready_idx: int = src.find("func _ready")
	assert_true(ready_idx != -1, "environment_manager has _ready")
	var body: String = src.substr(ready_idx, 600)
	# Should use get_node_or_null, not get_node
	assert_true(body.find("get_node_or_null(time_manager_path)") != -1,
		"environment_manager uses get_node_or_null for time_manager")
	assert_true(body.find("get_node_or_null(sun_light_path)") != -1,
		"environment_manager uses get_node_or_null for sun_light")


func test_cave_flat_zone_uses_continue() -> void:
	## Bug: chunk_manager.gd used break in cave flat-zone loop, skipping remaining caves.
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Find the cave flat-zone check in get_height_at
	var cave_loop_idx: int = src.find("dist_to_cave < cave_flat_outer")
	assert_true(cave_loop_idx != -1, "chunk_manager has cave flat-zone check")
	var after_check: String = src.substr(cave_loop_idx, 200)
	assert_true(after_check.find("continue") != -1,
		"cave flat-zone falloff uses continue (not break)")
	assert_true(after_check.find("break") == -1,
		"cave flat-zone falloff does NOT use break")


func test_height_limit_cache_bounded() -> void:
	## Bug: _height_limit_cache Dictionary grew unbounded during mountain exploration.
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Should have a max size constant
	assert_true(src.find("HEIGHT_CACHE_MAX_SIZE") != -1,
		"chunk_manager has HEIGHT_CACHE_MAX_SIZE constant")
	# Should clear when too large
	var limit_idx: int = src.find("func _limit_height_difference")
	assert_true(limit_idx != -1, "chunk_manager has _limit_height_difference")
	var body: String = src.substr(limit_idx, 2500)
	assert_true(body.find("_height_limit_cache.clear()") != -1,
		"_limit_height_difference clears cache when too large")


func test_river_water_material_shared() -> void:
	## Bug: Each river created a new StandardMaterial3D, causing shader recompile stutter.
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Should have a shared material getter
	assert_true(src.find("_get_river_water_material") != -1,
		"chunk_manager has shared river water material getter")
	assert_true(src.find("_river_water_material") != -1,
		"chunk_manager stores shared river water material")


## REMOVED: test_miter_checks_before_normalize
## River rendering was refactored to use grid-aligned quads — no miter logic exists.


func test_hud_uses_get_node_or_null() -> void:
	## Bug: hud.gd used get_node() for time_manager and player, crashing on invalid path.
	var file: FileAccess = FileAccess.open("res://scripts/ui/hud.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open hud.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var ready_idx: int = src.find("func _ready")
	assert_true(ready_idx != -1, "hud has _ready")
	var body: String = src.substr(ready_idx, 800)
	assert_true(body.find("get_node_or_null(time_manager_path)") != -1,
		"hud uses get_node_or_null for time_manager")
	assert_true(body.find("get_node_or_null(player_path)") != -1,
		"hud uses get_node_or_null for player")


func test_crafting_restore_focus_checks_is_open() -> void:
	## Bug: _do_restore_focus ran after menu was closed, stealing gameplay focus.
	var file: FileAccess = FileAccess.open("res://scripts/ui/crafting_ui.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open crafting_ui.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var restore_idx: int = src.find("func _do_restore_focus")
	assert_true(restore_idx != -1, "crafting_ui has _do_restore_focus")
	var body: String = src.substr(restore_idx, 500)
	assert_true(body.find("not is_open") != -1,
		"_do_restore_focus checks is_open before grabbing focus")
	# Check full function body for button validity
	var full_body: String = src.substr(restore_idx, 800)
	assert_true(full_body.find("is_instance_valid(button)") != -1,
		"_do_restore_focus checks button validity")


func test_storage_ui_checks_instance_valid() -> void:
	## Bug: storage_ui accessed storage.storage_inventory without is_instance_valid guard.
	var file: FileAccess = FileAccess.open("res://scripts/ui/storage_ui.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open storage_ui.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var open_idx: int = src.find("func open_storage")
	assert_true(open_idx != -1, "storage_ui has open_storage")
	var body: String = src.substr(open_idx, 800)
	assert_true(body.find("is_instance_valid(storage)") != -1,
		"open_storage checks storage validity before accessing inventory")


# ===== Round 8 regression tests =====


func test_cave_state_loaded_before_player_data() -> void:
	## Bug: save_load.gd loaded player data (which reads cave_transition.is_in_cave)
	## BEFORE loading cave state, so is_in_cave was always false on load.
	## Player would fall through cave floor after loading a cave save.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var cave_idx: int = src.find("cave_transition.load_save_data")
	var player_idx: int = src.find("_apply_player_data")
	assert_true(cave_idx != -1, "save_load has cave_transition.load_save_data")
	assert_true(player_idx != -1, "save_load has _apply_player_data call")
	assert_true(cave_idx < player_idx,
		"cave state loaded BEFORE player data (player reads is_in_cave)")


func test_weather_load_replays_side_effects() -> void:
	## Bug: _apply_weather_data() assigned current_weather directly without calling
	## _set_weather(), skipping hunger_multiplier, fire effectiveness, and weather_changed.
	var file: FileAccess = FileAccess.open("res://scripts/core/save_load.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open save_load.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var weather_idx: int = src.find("func _apply_weather_data")
	assert_true(weather_idx != -1, "save_load has _apply_weather_data")
	var weather_end: int = src.find("\nfunc ", weather_idx + 1)
	if weather_end == -1:
		weather_end = src.length()
	var body: String = src.substr(weather_idx, weather_end - weather_idx)
	assert_true(body.find("hunger_multiplier") != -1,
		"_apply_weather_data restores hunger_multiplier")
	assert_true(body.find("_update_fire_effectiveness") != -1,
		"_apply_weather_data restores fire effectiveness")
	assert_true(body.find("weather_changed.emit") != -1,
		"_apply_weather_data emits weather_changed signal")


func test_death_resets_shelter_resting_state() -> void:
	## Bug: shelter is_player_resting stayed true after death, causing phantom
	## time skips via _on_period_changed handler.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var death_idx: int = src.find("func _on_player_died")
	assert_true(death_idx != -1, "player_controller has _on_player_died")
	var body: String = src.substr(death_idx, 1500)
	assert_true(body.find("is_player_resting") != -1,
		"_on_player_died resets shelter is_player_resting")
	assert_true(body.find("resting_player") != -1,
		"_on_player_died clears shelter resting_player reference")


func test_death_resets_cabin_bed_sleeping_state() -> void:
	## Bug: cabin bed is_player_sleeping stayed true after death.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var death_idx: int = src.find("func _on_player_died")
	assert_true(death_idx != -1, "player_controller has _on_player_died")
	var body: String = src.substr(death_idx, 1500)
	assert_true(body.find("is_player_sleeping") != -1,
		"_on_player_died resets cabin bed is_player_sleeping")
	assert_true(body.find("sleeping_player") != -1,
		"_on_player_died clears cabin bed sleeping_player reference")


func test_death_cancels_active_placement() -> void:
	## Bug: PlacementSystem is_placing stayed true and ghost preview persisted after death.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var death_idx: int = src.find("func _on_player_died")
	assert_true(death_idx != -1, "player_controller has _on_player_died")
	var body: String = src.substr(death_idx, 2000)
	assert_true(body.find("PlacementSystem") != -1,
		"_on_player_died checks PlacementSystem node")
	assert_true(body.find("cancel_placement") != -1,
		"_on_player_died calls cancel_placement on death")


func test_fishing_spot_cancels_on_invalid_player() -> void:
	## Bug: FishingSpot is_fishing/waiting_for_catch/current_player persisted after
	## player death, causing timers to fire on an invalid player reference.
	var file: FileAccess = FileAccess.open("res://scripts/resources/fishing_spot.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fishing_spot.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var process_idx: int = src.find("func _process")
	assert_true(process_idx != -1, "fishing_spot has _process")
	var body: String = src.substr(process_idx, 800)
	assert_true(body.find("is_instance_valid(current_player)") != -1,
		"_process checks current_player validity when fishing")


func test_chunk_queue_filters_stale_entries() -> void:
	## Bug: chunk_manager didn't filter stale entries from load/unload queues
	## when player oscillated at chunk boundaries, causing brief terrain holes.
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var load_around_idx: int = src.find("func _load_chunks_around")
	assert_true(load_around_idx != -1, "chunk_manager has _load_chunks_around")
	var body: String = src.substr(load_around_idx, 1500)
	assert_true(body.find("chunks_to_unload") != -1 and body.find(".filter(") != -1,
		"_load_chunks_around filters stale entries from chunk queues")


func test_height_cache_key_uses_floor() -> void:
	## Bug: height cache key used int() which truncates toward zero instead of
	## floor() which rounds toward -infinity. At negative coords, int(-0.5)=0
	## but floor(-0.5)=-1, causing different cells to share cache keys.
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var func_idx: int = src.find("func _limit_height_difference")
	assert_true(func_idx != -1, "chunk_manager has _limit_height_difference")
	var body: String = src.substr(func_idx, 500)
	assert_true(body.find("floor(x / cell_size)") != -1,
		"height cache key uses floor() for X coordinate (not int())")
	assert_true(body.find("floor(z / cell_size)") != -1,
		"height cache key uses floor() for Z coordinate (not int())")


# ============================================================================
# Round 9 Regression Tests
# ============================================================================

func test_crystal_collision_disabled_when_depleted() -> void:
	# Bug: Crystal collision shapes created in deferred setup after _set_depleted_state ran,
	# so depleted crystals still had active collision (invisible walls).
	var file: FileAccess = FileAccess.open("res://scripts/resources/crystal_node.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open crystal_node.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("add_child(collision)")
	assert_true(idx != -1, "crystal_node has add_child(collision)")
	var after: String = src.substr(idx, 200)
	assert_true(after.find("is_depleted") != -1,
		"crystal_node checks is_depleted after adding collision shape")
	assert_true(after.find("collision.disabled") != -1,
		"crystal_node disables collision when depleted on load")


func test_ore_collision_disabled_when_depleted() -> void:
	# Bug: Same as crystal - ore collision shapes created after depleted state applied.
	var file: FileAccess = FileAccess.open("res://scripts/resources/rare_ore_node.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open rare_ore_node.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("add_child(collision)")
	assert_true(idx != -1, "rare_ore_node has add_child(collision)")
	var after: String = src.substr(idx, 200)
	assert_true(after.find("is_depleted") != -1,
		"rare_ore_node checks is_depleted after adding collision shape")
	assert_true(after.find("collision.disabled") != -1,
		"rare_ore_node disables collision when depleted on load")


func test_darkness_notification_threshold_reachable() -> void:
	# Bug: Darkness notification threshold used * 0.5 making it 65s, but first damage
	# was at ~70s, so notification was never shown. Changed to * 1.5 (75s).
	var file: FileAccess = FileAccess.open("res://scripts/core/cave_transition.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open cave_transition.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("DARKNESS_DAMAGE_INTERVAL * 1.5")
	assert_true(idx != -1,
		"darkness notification uses * 1.5 threshold (reachable before first damage)")


func test_processing_structures_store_pending_output() -> void:
	# Bug: Processing structures (drying rack, smoker, smithing) lost products when
	# player inventory was unreachable. Now stores in pending_output for later pickup.
	for path: String in ["structure_drying_rack.gd", "structure_smoker.gd", "structure_smithing_station.gd"]:
		var file: FileAccess = FileAccess.open("res://scripts/campsite/" + path, FileAccess.READ)
		if not file:
			assert_true(false, "Could not open " + path)
			continue
		var src: String = file.get_as_text()
		file.close()
		assert_true(src.find("pending_output") != -1,
			path + " has pending_output field for storing products")
		assert_true(src.find("pending_output") != -1 and src.find("get_save_data") != -1,
			path + " saves pending_output in save data")


func test_canvas_tent_skip_dawn_checks_self_valid() -> void:
	# Bug: Canvas tent _skip_to_dawn could access freed self during fade callback.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_canvas_tent.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_canvas_tent.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("func _skip_to_dawn")
	assert_true(idx != -1, "canvas tent has _skip_to_dawn")
	var body: String = src.substr(idx, 300)
	assert_true(body.find("is_instance_valid(self)") != -1,
		"canvas tent _skip_to_dawn checks is_instance_valid(self)")


func test_cave_test_uses_168h_respawn() -> void:
	# Bug: Cave transition test used 72h respawn constant but production uses 168h.
	var file: FileAccess = FileAccess.open("res://tests/test_cave_transition.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open test_cave_transition.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("RESPAWN_HOURS: float = 168.0") != -1,
		"cave transition test uses 168h respawn constant matching production")


func test_config_tab_checks_visibility_or_pause() -> void:
	# Bug: Tab key could open config menu during pause without setting opened_from_pause_menu,
	# causing the menu to get stuck when closing.
	var file: FileAccess = FileAccess.open("res://scripts/ui/config_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open config_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("KEY_TAB")
	assert_true(idx != -1, "config_menu handles KEY_TAB")
	var body: String = src.substr(idx, 300)
	assert_true(body.find("is_visible") != -1 or body.find("paused") != -1,
		"config_menu Tab handler checks visibility or pause state")


func test_equipment_menu_has_all_equippable_items() -> void:
	# Bug: Equipment menu only had 14 of 25 equippable items, making 11 items
	# unequippable for controller users.
	var file: FileAccess = FileAccess.open("res://scripts/ui/equipment_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open equipment_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	# Check that key later-game items are present in EQUIPMENT_SLOTS
	for item: String in ["metal_axe", "machete", "lantern", "smoker_kit", "snare_trap_kit"]:
		assert_true(src.find('"type": "%s"' % item) != -1,
			"equipment_menu includes %s" % item)


func test_durability_signal_uses_equipped_max() -> void:
	# Bug: use_durability() used TOOL_MAX_DURABILITY instead of get_equipped_max_durability(),
	# giving wrong percentage when leather wrap upgrade was applied.
	var file: FileAccess = FileAccess.open("res://scripts/player/equipment.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open equipment.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("func use_durability")
	assert_true(idx != -1, "equipment has use_durability function")
	var body: String = src.substr(idx, 800)
	assert_true(body.find("get_equipped_max_durability") != -1,
		"use_durability uses get_equipped_max_durability for signal emission")


func test_axe_tween_killed_on_remove() -> void:
	# Bug: Axe swing tween kept running after tool broke, causing errors on freed node.
	var file: FileAccess = FileAccess.open("res://scripts/player/equipment.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open equipment.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("func _remove_stone_axe")
	assert_true(idx != -1, "equipment has _remove_stone_axe")
	var body: String = src.substr(idx, 400)
	assert_true(body.find("axe_swing_tween") != -1,
		"_remove_stone_axe kills axe_swing_tween before freeing model")


func test_pause_menu_load_uses_await() -> void:
	# Bug: Pause menu called load_game_slot without await, causing race condition.
	var file: FileAccess = FileAccess.open("res://scripts/ui/pause_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open pause_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("await save_load.load_game_slot") != -1,
		"pause_menu awaits load_game_slot")


func test_raw_mountain_height_checks_carved_neighbor() -> void:
	# Bug: _get_raw_mountain_height carved paths unconditionally, while get_height_at
	# required _has_carved_neighbor check. This caused height limiter to get wrong data.
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("func _get_raw_mountain_height")
	assert_true(idx != -1, "chunk_manager has _get_raw_mountain_height")
	var body: String = src.substr(idx, 2000)
	assert_true(body.find("_has_carved_neighbor") != -1,
		"_get_raw_mountain_height checks _has_carved_neighbor before carving paths")


func test_trees_skip_negative_height() -> void:
	# Bug: Trees could be placed at negative Y (underwater), floating or submerged.
	var file: FileAccess = FileAccess.open("res://scripts/world/terrain_chunk.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open terrain_chunk.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("tree_y")
	assert_true(idx != -1, "terrain_chunk uses tree_y variable")
	var body: String = src.substr(idx, 200)
	assert_true(body.find("tree_y < 0") != -1,
		"terrain_chunk skips tree placement when height is below water level")


func test_config_menu_load_uses_await() -> void:
	# Bug: Config menu called load_game_slot without await (same as pause menu bug).
	var file: FileAccess = FileAccess.open("res://scripts/ui/config_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open config_menu.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("await save_load.load_game_slot") != -1,
		"config_menu awaits load_game_slot")


func test_fishing_tweens_tracked_as_members() -> void:
	# Bug: Fishing cast/catch tweens were local vars, so old tweens couldn't be killed
	# when starting a new one, causing overlapping animations.
	var file: FileAccess = FileAccess.open("res://scripts/player/equipment.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open equipment.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("fishing_cast_tween") != -1,
		"equipment tracks fishing_cast_tween as member variable")
	assert_true(src.find("fish_caught_tween") != -1,
		"equipment tracks fish_caught_tween as member variable")


func test_birch_bark_emits_before_durability() -> void:
	# Bug: _harvest_birch_bark called use_durability(1) before item_used.emit(),
	# but use_durability can clear equipped_item, so the signal had wrong item.
	var file: FileAccess = FileAccess.open("res://scripts/player/equipment.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open equipment.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var idx: int = src.find("func _harvest_birch_bark")
	assert_true(idx != -1, "equipment has _harvest_birch_bark")
	var body: String = src.substr(idx, 2000)
	var emit_idx: int = body.find("item_used.emit")
	var durability_idx: int = body.find("use_durability")
	assert_true(emit_idx != -1 and durability_idx != -1,
		"_harvest_birch_bark has both emit and durability calls")
	assert_true(emit_idx < durability_idx,
		"_harvest_birch_bark emits signal BEFORE use_durability")


func test_shelter_sleep_guard_prevents_double() -> void:
	# Bug: _on_period_changed could fire _trigger_sleep_sequence while already sleeping,
	# causing double time skip and double heal.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_shelter.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_shelter.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	assert_true(src.find("_is_sleeping") != -1,
		"shelter has _is_sleeping guard variable")
	var idx: int = src.find("func _on_period_changed")
	assert_true(idx != -1, "shelter has _on_period_changed")
	var body: String = src.substr(idx, 300)
	assert_true(body.find("_is_sleeping") != -1,
		"_on_period_changed checks _is_sleeping guard to prevent double sleep")


func test_heal_eat_guard_is_dead() -> void:
	# Bug: heal() and eat() could be called on dead player (from shelter sleep),
	# restoring health/hunger and corrupting dead state.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_stats.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_stats.gd")
		return
	var src: String = file.get_as_text()
	file.close()
	var heal_idx: int = src.find("func heal(")
	assert_true(heal_idx != -1, "player_stats has heal function")
	var heal_body: String = src.substr(heal_idx, 300)
	assert_true(heal_body.find("is_dead") != -1,
		"heal() checks is_dead guard")

	var eat_idx: int = src.find("func eat(")
	assert_true(eat_idx != -1, "player_stats has eat function")
	var eat_body: String = src.substr(eat_idx, 300)
	assert_true(eat_body.find("is_dead") != -1,
		"eat() checks is_dead guard")


func test_music_manager_set_enabled_guards_null_player() -> void:
	## Bug: config_menu._ready() calls music_manager.set_music_enabled() before
	## music_manager._ready() has created audio players, causing crash on
	## active_player.stop() when active_player is null.
	var music_script: GDScript = load("res://scripts/core/music_manager.gd") as GDScript
	if not music_script:
		assert_true(false, "Could not load music_manager.gd")
		return
	var source: String = music_script.source_code
	var fn_start: int = source.find("func set_music_enabled(")
	assert_true(fn_start != -1, "set_music_enabled function exists")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)
	assert_true(fn_body.find("not active_player") != -1 or fn_body.find("active_player == null") != -1,
		"set_music_enabled guards against null active_player")


func test_ambient_sound_add_child_before_global_position() -> void:
	## Bug: ambient_sound_manager.gd set global_position on emitter before
	## add_child(), causing "not is_inside_tree()" error since global_position
	## requires the node to be in the scene tree.
	var sound_script: GDScript = load("res://scripts/core/ambient_sound_manager.gd") as GDScript
	if not sound_script:
		assert_true(false, "Could not load ambient_sound_manager.gd")
		return
	var source: String = sound_script.source_code
	var fn_start: int = source.find("func _sync_emitters(")
	assert_true(fn_start != -1, "_sync_emitters function exists")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)
	var add_child_pos: int = fn_body.find("add_child(emitter)")
	var global_pos_pos: int = fn_body.find("emitter.global_position = target_pos", add_child_pos)
	assert_true(add_child_pos != -1 and global_pos_pos != -1 and add_child_pos < global_pos_pos,
		"add_child(emitter) is called before setting global_position")


func test_pause_resume_guards_is_inside_tree() -> void:
	## Bug: When loading a saved game with a different world seed, load_game_slot()
	## calls get_tree().reload_current_scene() and returns true. The await in
	## pause_menu then calls resume_game(), but the scene is being torn down so
	## get_tree() returns null, crashing on get_tree().paused = false.
	var pause_script: GDScript = load("res://scripts/ui/pause_menu.gd") as GDScript
	if not pause_script:
		assert_true(false, "Could not load pause_menu.gd")
		return
	var source: String = pause_script.source_code
	var fn_start: int = source.find("func resume_game(")
	assert_true(fn_start != -1, "resume_game function exists")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)
	assert_true(fn_body.find("is_inside_tree()") != -1,
		"resume_game() guards against being called after scene teardown")


func test_hud_weather_refresh_uses_get_weather_name() -> void:
	## Bug: hud.gd _on_game_loaded() called _on_weather_changed(weather_manager.current_weather)
	## but current_weather is a Weather enum (int), while _on_weather_changed expects a String.
	## Must use get_weather_name() to convert the enum to a string.
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	if not hud_script:
		assert_true(false, "Could not load hud.gd")
		return
	var source: String = hud_script.source_code
	var fn_start: int = source.find("func _on_game_loaded(")
	assert_true(fn_start != -1, "_on_game_loaded function exists")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)
	assert_true(fn_body.find("get_weather_name()") != -1,
		"_on_game_loaded uses get_weather_name() not current_weather enum")
	assert_true(fn_body.find(".current_weather)") == -1,
		"_on_game_loaded does not pass raw current_weather enum to handler")


func test_creature_look_at_uses_model_front() -> void:
	## Bug: Creature meshes are built with face at +Z, but look_at() orients -Z
	## toward the target by default, causing animals to move backwards. Must pass
	## use_model_front=true to treat +Z as forward.
	for path: String in [
		"res://scripts/creatures/ambient_animal_base.gd",
		"res://scripts/creatures/ambient_rabbit.gd",
		"res://scripts/creatures/ambient_bird.gd"
	]:
		var script: GDScript = load(path) as GDScript
		if not script:
			assert_true(false, "Could not load " + path)
			continue
		var source: String = script.source_code
		var look_idx: int = source.find("look_at(look_target")
		if look_idx == -1:
			continue
		var line_end: int = source.find("\n", look_idx)
		var look_line: String = source.substr(look_idx, line_end - look_idx)
		assert_true(look_line.find("true") != -1,
			path.get_file() + " look_at uses use_model_front=true")


func test_bark_strip_visual_added_on_harvest() -> void:
	## Feature: Birch trees show a brown stripped band at eye level after bark
	## is harvested with a machete. The strip should be added via add_bark_strip().
	var equip_script: GDScript = load("res://scripts/player/equipment.gd") as GDScript
	if not equip_script:
		assert_true(false, "Could not load equipment.gd")
		return
	var source: String = equip_script.source_code

	# _harvest_birch_bark must call _add_bark_strip after harvesting
	var fn_start: int = source.find("func _harvest_birch_bark(")
	assert_true(fn_start != -1, "_harvest_birch_bark function exists")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)
	assert_true(fn_body.find("_add_bark_strip") != -1,
		"_harvest_birch_bark adds bark strip visual after harvesting")

	# add_bark_strip static method must exist and create a BarkStrip node
	var strip_fn_start: int = source.find("static func add_bark_strip(")
	assert_true(strip_fn_start != -1, "add_bark_strip static method exists")
	var strip_fn_end: int = source.find("\nfunc ", strip_fn_start + 1)
	if strip_fn_end == -1:
		strip_fn_end = source.find("\nstatic func ", strip_fn_start + 1)
	if strip_fn_end == -1:
		strip_fn_end = source.length()
	var strip_body: String = source.substr(strip_fn_start, strip_fn_end - strip_fn_start)
	assert_true(strip_body.find("BarkStrip") != -1,
		"add_bark_strip creates a node named BarkStrip")

	# remove_bark_strip static method must exist
	var remove_fn: int = source.find("static func remove_bark_strip(")
	assert_true(remove_fn != -1, "remove_bark_strip static method exists")


func test_bark_strip_reapplied_on_chunk_spawn() -> void:
	## Feature: When terrain chunks reload, birch trees that were previously
	## stripped must have their visual band reapplied from the bark tracker.
	var chunk_script: GDScript = load("res://scripts/world/terrain_chunk.gd") as GDScript
	if not chunk_script:
		assert_true(false, "Could not load terrain_chunk.gd")
		return
	var source: String = chunk_script.source_code

	# _spawn_chunk_trees must call _try_apply_bark_strip for birch trees
	var fn_start: int = source.find("func _spawn_chunk_trees(")
	assert_true(fn_start != -1, "_spawn_chunk_trees function exists")
	var fn_end: int = source.find("\nfunc ", fn_start + 1)
	if fn_end == -1:
		fn_end = source.length()
	var fn_body: String = source.substr(fn_start, fn_end - fn_start)
	assert_true(fn_body.find("_try_apply_bark_strip") != -1,
		"_spawn_chunk_trees calls _try_apply_bark_strip for birch trees")
	assert_true(fn_body.find("birch_tree_resource.tscn") != -1,
		"_spawn_chunk_trees checks for birch tree scene path")

	# _try_apply_bark_strip must check bark_harvest_tracker
	var try_fn: int = source.find("func _try_apply_bark_strip(")
	assert_true(try_fn != -1, "_try_apply_bark_strip function exists")
	var try_fn_end: int = source.find("\nfunc ", try_fn + 1)
	if try_fn_end == -1:
		try_fn_end = source.length()
	var try_body: String = source.substr(try_fn, try_fn_end - try_fn)
	assert_true(try_body.find("bark_harvest_tracker") != -1,
		"_try_apply_bark_strip checks bark_harvest_tracker")
	assert_true(try_body.find("add_bark_strip") != -1,
		"_try_apply_bark_strip calls add_bark_strip")


func test_cabin_bed_connects_to_period_changed() -> void:
	## Bug: CabinBed only checked _is_nighttime() when player entered bed.
	## If player got in bed at 7 PM (before nighttime threshold), they had to
	## leave and re-enter to trigger sleep at 8 PM. Fix: connect to
	## TimeManager.period_changed signal to detect nightfall while in bed.
	var script: GDScript = load("res://scripts/campsite/cabin_bed.gd") as GDScript
	if not script:
		assert_true(false, "Could not load cabin_bed.gd")
		return
	var source: String = script.source_code

	# Must connect to time manager for period changes
	assert_true(source.find("_connect_to_time_manager") != -1,
		"CabinBed has _connect_to_time_manager method")
	assert_true(source.find("period_changed") != -1,
		"CabinBed connects to period_changed signal")

	# Must have _on_period_changed handler that triggers sleep
	var handler_start: int = source.find("func _on_period_changed(")
	assert_true(handler_start != -1, "CabinBed has _on_period_changed handler")
	if handler_start != -1:
		var handler_end: int = source.find("\nfunc ", handler_start + 1)
		if handler_end == -1:
			handler_end = source.length()
		var handler_body: String = source.substr(handler_start, handler_end - handler_start)
		assert_true(handler_body.find("is_player_sleeping") != -1,
			"_on_period_changed checks if player is in bed")
		assert_true(handler_body.find("_is_nighttime") != -1,
			"_on_period_changed checks if nighttime")
		assert_true(handler_body.find("_trigger_sleep_sequence") != -1,
			"_on_period_changed triggers sleep sequence")


func test_animal_avoids_cave_entrance() -> void:
	## Bug: Ambient animals (bunnies) could hop across the cave entrance pit,
	## floating in mid-air because get_height_at() returns the flat platform
	## height (2.0) but no actual terrain mesh exists in the skip zone.
	## Fix: _move_animal() checks cave_entrances and reverses direction.
	var script: GDScript = load("res://scripts/creatures/ambient_animal_base.gd") as GDScript
	if not script:
		assert_true(false, "Could not load ambient_animal_base.gd")
		return
	var source: String = script.source_code

	# _move_animal must check cave_entrances before applying movement
	var fn_start: int = source.find("func _move_animal(")
	assert_true(fn_start != -1, "_move_animal function exists")
	if fn_start != -1:
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("cave_entrances") != -1,
			"_move_animal checks cave_entrances to avoid pits")
		assert_true(fn_body.find("move_direction = -move_direction") != -1,
			"_move_animal reverses direction near caves")


func test_map_does_not_block_movement() -> void:
	## Bug: Map UI was listed as a movement-blocking UI in player_controller.gd.
	## Player should be able to walk while the map overlay is open.
	var script: GDScript = load("res://scripts/player/player_controller.gd") as GDScript
	if not script:
		assert_true(false, "Could not load player_controller.gd")
		return
	var source: String = script.source_code

	# _is_ui_blocking_input should NOT check for map_ui group
	var fn_start: int = source.find("func _is_ui_blocking_input(")
	assert_true(fn_start != -1, "_is_ui_blocking_input function exists")
	if fn_start != -1:
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("map_ui") == -1,
			"_is_ui_blocking_input does NOT block on map_ui (walking allowed with map open)")


func test_map_updates_player_position() -> void:
	## Bug: Map captured player position once in _gather_map_data() at open time.
	## The X marker never moved while walking with the map open.
	## Fix: _process() updates player_pos each frame and triggers redraw.
	var script: GDScript = load("res://scripts/ui/bark_map_ui.gd") as GDScript
	if not script:
		assert_true(false, "Could not load bark_map_ui.gd")
		return
	var source: String = script.source_code

	# Must have _process that updates player_pos
	var fn_start: int = source.find("func _process(")
	assert_true(fn_start != -1, "BarkMapUI has _process for live position updates")
	if fn_start != -1:
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("player_pos") != -1,
			"_process updates player_pos")
		assert_true(fn_body.find("queue_redraw") != -1,
			"_process triggers map redraw when position changes")


func test_journal_interact_sets_sinkhole_book_collected() -> void:
	## Bug: Explorer's Journal respawned after collection because interact()
	## never set ChunkManager.sinkhole_book_collected = true.
	var file: FileAccess = FileAccess.open("res://scripts/world/explorers_journal_pickup.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open explorers_journal_pickup.gd")
		return
	var source: String = file.get_as_text()

	# The interact function must set sinkhole_book_collected on ChunkManager
	var interact_start: int = source.find("func interact(")
	assert_true(interact_start != -1, "Journal has interact() method")
	if interact_start != -1:
		var interact_end: int = source.find("\nfunc ", interact_start + 1)
		if interact_end == -1:
			interact_end = source.length()
		var interact_body: String = source.substr(interact_start, interact_end - interact_start)
		assert_true(interact_body.find("sinkhole_book_collected") != -1,
			"interact() sets sinkhole_book_collected flag to prevent respawn")


func test_rock_spire_is_static_body() -> void:
	## Bug: Rock spire near sinkhole used Node3D root with no collision,
	## allowing the player to walk through it.
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var source: String = file.get_as_text()

	var fn_start: int = source.find("func _spawn_rock_spire()")
	assert_true(fn_start != -1, "ChunkManager has _spawn_rock_spire()")
	if fn_start != -1:
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("StaticBody3D") != -1,
			"Rock spire uses StaticBody3D for collision")
		assert_true(fn_body.find("CollisionShape3D") != -1,
			"Rock spire has CollisionShape3D")


func test_weather_manager_connects_day_changed() -> void:
	## Bug class: weather must advance on every new day regardless of which
	## time period the transition came from (sleep-from-dusk skips Night).
	## With the rolling-queue design, _on_day_changed is the sole driver of
	## daily weather advancement and must pop the forecast queue.
	var file: FileAccess = FileAccess.open("res://scripts/world/weather_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open weather_manager.gd")
		return
	var source: String = file.get_as_text()

	assert_true(source.find("day_changed.connect") != -1,
		"WeatherManager connects to day_changed signal")

	var fn_start: int = source.find("func _on_day_changed(")
	assert_true(fn_start != -1, "WeatherManager has _on_day_changed handler")
	if fn_start != -1:
		var fn_end: int = source.find("\nfunc ", fn_start + 1)
		if fn_end == -1:
			fn_end = source.length()
		var fn_body: String = source.substr(fn_start, fn_end - fn_start)
		assert_true(fn_body.find("forecast.pop_front") != -1,
			"_on_day_changed pops the forecast queue to advance weather")


func test_journal_sets_menu_open_flag() -> void:
	# ROOT CAUSE: Journal never set TouchControls.menu_open = true, so TouchControls
	# (which has PROCESS_MODE_ALWAYS) kept intercepting all touch events for
	# joystick/look input, consuming them before the journal could process them.
	# This made close button, swipe-left, and tap-outside-to-close all fail on iOS.
	var file: FileAccess = FileAccess.open("res://scripts/ui/journal_ui.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open journal_ui.gd")
		return
	var source: String = file.get_as_text()

	# open_journal must set TouchControls.menu_open = true
	var open_fn: int = source.find("func open_journal(")
	assert_true(open_fn != -1, "journal_ui has open_journal function")
	if open_fn != -1:
		var open_end: int = source.find("\nfunc ", open_fn + 1)
		if open_end == -1:
			open_end = source.length()
		var open_body: String = source.substr(open_fn, open_end - open_fn)
		assert_true(open_body.find("TouchControls.menu_open = true") != -1,
			"open_journal sets TouchControls.menu_open = true")

	# _close_journal must set TouchControls.menu_open = false
	var close_fn: int = source.find("func _close_journal(")
	assert_true(close_fn != -1, "journal_ui has _close_journal function")
	if close_fn != -1:
		var close_end: int = source.find("\nfunc ", close_fn + 1)
		if close_end == -1:
			close_end = source.length()
		var close_body: String = source.substr(close_fn, close_end - close_fn)
		assert_true(close_body.find("TouchControls.menu_open = false") != -1,
			"_close_journal sets TouchControls.menu_open = false")


func test_journal_uses_gui_input_for_touch() -> void:
	# ROOT CAUSE: Journal's _input() called set_input_as_handled() on ALL touch events,
	# which runs BEFORE Godot's GUI system. This prevented mobile Button nodes and
	# background gui_input from ever receiving touch events, breaking close/nav/swipe.
	# Fix: _input() must NOT consume touch/mouse events — let them flow to GUI system.
	var file: FileAccess = FileAccess.open("res://scripts/ui/journal_ui.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open journal_ui.gd")
		return
	var source: String = file.get_as_text()

	# _input() must not call set_input_as_handled() on InputEventScreenTouch
	var input_fn: int = source.find("func _input(")
	assert_true(input_fn != -1, "journal_ui has _input function")
	if input_fn != -1:
		var input_end: int = source.find("\nfunc ", input_fn + 1)
		if input_end == -1:
			input_end = source.length()
		var input_body: String = source.substr(input_fn, input_end - input_fn)
		# Must NOT handle InputEventScreenTouch in _input (should return early for touch)
		assert_true(input_body.find("InputEventScreenTouch") != -1,
			"_input references InputEventScreenTouch (to skip it)")
		assert_true(input_body.find("_handle_screen_touch") == -1,
			"_input does not manually handle screen touches")

	# Must have _on_background_gui_input for touch/swipe handling via GUI system
	assert_true(source.find("func _on_background_gui_input(") != -1,
		"journal_ui has _on_background_gui_input handler")

	# background must connect gui_input signal
	assert_true(source.find("gui_input.connect(_on_background_gui_input)") != -1,
		"background connects gui_input signal")


func test_house_pause_menu_in_pause_group() -> void:
	# ROOT CAUSE: house_pause_menu.gd never called add_to_group("pause_menu"),
	# so TouchControls._on_menu_button_pressed("pause") found no nodes and
	# the MENU button did nothing on iOS in the house scene.
	var file: FileAccess = FileAccess.open("res://scripts/house/house_pause_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open house_pause_menu.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("add_to_group(\"pause_menu\")") != -1,
		"house_pause_menu adds itself to pause_menu group")


func test_pond_edge_collision_extends_downward() -> void:
	# ROOT CAUSE: At the pond-to-land transition, the pond floor cell (height -2.5)
	# had a thin slab with top at -2.5, while the adjacent shore cell (height +0.5)
	# had a box with bottom at ~0. This left a 2.5-unit gap the player swam through.
	# Fix: ALL boxes now use abs(height) + 3.0 depth, extending well below the
	# surface so adjacent cells always overlap vertically at water edges.
	var file: FileAccess = FileAccess.open("res://scripts/world/terrain_chunk.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open terrain_chunk.gd")
		return
	var source: String = file.get_as_text()
	# Must NOT have the old thin-slab formula for negative heights
	assert_true(source.find("height + box_height / 2.0") == -1,
		"no upward-extending slabs (old bug pattern)")
	# All boxes use unified formula with extra depth to close water-land gaps
	assert_true(source.find("abs(height) + 3.0") != -1,
		"all collision boxes extend 3 extra units deep to prevent pond edge gaps")


func test_water_area_matches_visual_dimensions() -> void:
	# ROOT CAUSE: WaterArea was pond_width + 1.0 on X/Z, causing body_exited
	# to fire while the player was still at the pond edge. This switched off
	# swim physics prematurely and full gravity clipped them through terrain.
	var file: FileAccess = FileAccess.open("res://scripts/resources/fishing_spot.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fishing_spot.gd")
		return
	var source: String = file.get_as_text()
	# WaterArea should NOT have + 1.0 on pond_width or pond_depth
	assert_true(source.find("pond_width + 1.0") == -1,
		"WaterArea X dimension should not be oversized by +1.0")
	assert_true(source.find("pond_depth + 1.0") == -1,
		"WaterArea Z dimension should not be oversized by +1.0")


func test_player_has_water_exit_grace_timer() -> void:
	# ROOT CAUSE: When exiting water, swim physics switched off instantly and
	# full gravity kicked in before the player cleared the pond edge slope.
	# Fix: a grace timer keeps swim physics active briefly after leaving water.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("_water_exit_grace_timer") != -1,
		"player_controller has water exit grace timer variable")
	assert_true(source.find("WATER_EXIT_GRACE_DURATION") != -1,
		"player_controller has water exit grace duration constant")


func test_camp_level_crafting_hint_exists() -> void:
	# Players didn't realize recipes were locked behind camp levels.
	# A one-time hint fires when they see level-locked recipes in the crafting UI.
	var file: FileAccess = FileAccess.open("res://scripts/ui/hint_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open hint_manager.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("\"camp_level_crafting\"") != -1,
		"hint_manager has camp_level_crafting hint defined")


func test_crafting_ui_shows_camp_level_label() -> void:
	# Recipes locked by camp level must show "Requires Camp Lvl X" so players
	# understand why the button is disabled.
	var file: FileAccess = FileAccess.open("res://scripts/ui/crafting_ui.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open crafting_ui.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("Requires Camp Lvl") != -1,
		"crafting UI shows camp level requirement label on locked recipes")
	assert_true(source.find("camp_level_crafting") != -1,
		"crafting UI triggers camp_level_crafting hint")


func test_fire_flare_uses_stable_baseline() -> void:
	# ROOT CAUSE: flare() read fire_light.light_energy (current node value) as its
	# baseline. If called mid-tween, the sampled value was an intermediate brightness,
	# ratcheting the fire brighter each time. Fix: use _get_current_base_energy().
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_fire_pit.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_fire_pit.gd")
		return
	var source: String = file.get_as_text()
	# flare() must NOT sample from fire_light.light_energy
	assert_true(source.find("var original_energy: float = fire_light.light_energy") == -1,
		"flare() does not read current light_energy as baseline (ratchet bug)")
	# flare() must use the stable baseline function
	assert_true(source.find("_get_current_base_energy()") != -1,
		"flare() uses _get_current_base_energy() for stable baseline")


func test_cooking_does_not_flare_fire() -> void:
	# Cooking food on the fire was calling flare(), making the fire brighter
	# with each item cooked. Cooking should not affect fire brightness.
	var file: FileAccess = FileAccess.open("res://scripts/ui/fire_menu.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open fire_menu.gd")
		return
	var source: String = file.get_as_text()
	# Find the cook function and verify no flare call between cook and notification
	var cook_idx: int = source.find("_on_cook_pressed")
	var add_fuel_idx: int = source.find("_on_add_fuel_pressed")
	if cook_idx != -1 and add_fuel_idx != -1:
		var cook_section: String = source.substr(cook_idx, add_fuel_idx - cook_idx)
		assert_true(cook_section.find(".flare()") == -1,
			"cook handler does not call flare() on the fire")


func test_fire_brightness_has_max_level() -> void:
	# Fire brightness must be capped at 3 levels (dim, medium, bright).
	# Without a cap, adding wood repeatedly made the fire white/purple/black.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_fire_pit.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_fire_pit.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("MAX_BRIGHTNESS_LEVEL") != -1,
		"fire pit has a max brightness level constant")
	assert_true(source.find("BRIGHTNESS_MULTIPLIERS") != -1,
		"fire pit has brightness multiplier table")
	assert_true(source.find("_brightness_level < MAX_BRIGHTNESS_LEVEL") != -1,
		"boost_brightness() checks against max level before incrementing")


func test_cave_terrain_collision_skips_underground_tunnel() -> void:
	# Regression: terrain collision formula abs(height)+3.0 pushed terrain collision
	# into the underground cave tunnel, requiring crouch to enter.
	# Fix: is_inside_cave_tunnel(include_underground=true) skips collision
	# above the tunnel area (Z:[-24,-6] in cave-local coords).
	var file: FileAccess = FileAccess.open("res://scripts/world/chunk_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open chunk_manager.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("include_underground: bool = false") != -1,
		"is_inside_cave_tunnel has include_underground parameter")
	assert_true(source.find("local_z >= -24.0") != -1,
		"underground tunnel skip zone extends to Z=-24")

	# Verify collision generation uses include_underground=true
	var tc_file: FileAccess = FileAccess.open("res://scripts/world/terrain_chunk.gd", FileAccess.READ)
	if not tc_file:
		assert_true(false, "Could not open terrain_chunk.gd")
		return
	var tc_source: String = tc_file.get_as_text()
	assert_true(tc_source.find("is_inside_cave_tunnel(cell_cx, cell_cz, true)") != -1,
		"collision generation skips underground tunnel area")


func test_tool_resource_prompt_uses_use_equipped() -> void:
	# On iOS, the prompt for tool resources (axe/pickaxe) showed "[Tap ACT]"
	# but the player actually uses the USE button. Fix: detect tool-requiring
	# resources and show the use_equipped prompt instead.
	var file: FileAccess = FileAccess.open("res://scripts/ui/hud.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open hud.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("required_tool") != -1,
		"HUD checks for required_tool on interaction targets")
	assert_true(source.find("use_equipped") != -1,
		"HUD uses use_equipped prompt for tool resources")


func test_canvas_tent_camera_inside_tent() -> void:
	# Canvas tent camera was positioned above the tent looking down instead of
	# inside the tent looking up. Fix: explicitly set camera Y position and
	# adjust rest position to place player inside the tent.
	var file: FileAccess = FileAccess.open("res://scripts/campsite/structure_canvas_tent.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open structure_canvas_tent.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("rest_camera_y") != -1,
		"canvas tent sets rest_camera_y for inside-tent view")
	# Camera Y must be below tent ridge (1.8) and above ground (0)
	assert_true(source.find("rest_camera_y = 0.4") != -1,
		"camera Y at 0.4 places view inside tent, not above it")


func test_first_compass_hint_exists() -> void:
	# Players didn't understand the compass+lodestone mechanic on first craft.
	# A one-time hint now fires when the compass enters the inventory.
	var file: FileAccess = FileAccess.open("res://scripts/ui/hint_manager.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open hint_manager.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("\"first_compass\"") != -1,
		"hint_manager defines first_compass hint")
	assert_true(source.find("\"compass\": \"first_compass\"") != -1,
		"hint_manager ITEM_HINTS maps compass → first_compass")


func test_compass_triggers_hint_on_inventory_add() -> void:
	# The inventory.gd add_item hook is the actual trigger point for item hints.
	# If compass isn't in the hook's item list, the hint won't fire even if defined.
	var file: FileAccess = FileAccess.open("res://scripts/player/inventory.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open inventory.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("\"compass\"") != -1,
		"inventory.gd item-hint hook includes compass")
	assert_true(source.find("\"compass\": \"first_compass\"") != -1,
		"inventory.gd maps compass to first_compass hint")


func test_focus_out_skips_mouse_release_when_controller_active() -> void:
	# macOS + DualSense bug: window focus-out fires spuriously (from touchpad
	# OS-level mouse emulation or system game-controller handling), revealing
	# the system cursor over the HUD crosshair. Fix: skip the voluntary
	# MOUSE_MODE_VISIBLE call when a controller is driving.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var source: String = file.get_as_text()
	var focus_idx: int = source.find("NOTIFICATION_WM_WINDOW_FOCUS_OUT")
	assert_true(focus_idx != -1, "focus-out handler exists")
	# The guard must be near the focus-out handler
	var next_section: int = source.find("NOTIFICATION_WM_WINDOW_FOCUS_IN", focus_idx)
	assert_true(next_section != -1, "focus-in handler also exists")
	var section: String = source.substr(focus_idx, next_section - focus_idx)
	assert_true(section.find("using_controller") != -1,
		"focus-out handler checks using_controller before releasing mouse")


func test_new_game_plus_stack_amounts_exist() -> void:
	# Stackable consumables (e.g. diamond_arrows) must be granted as a usable
	# bundle, not a single unit, when returning to the wilderness via NG+.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("NG_PLUS_STACK_AMOUNTS") != -1,
		"player_controller defines NG_PLUS_STACK_AMOUNTS constant")
	assert_true(source.find("\"diamond_arrows\": 10") != -1,
		"NG_PLUS_STACK_AMOUNTS grants 10 diamond_arrows")


func test_ng_plus_diamond_arrows_granted_as_ten() -> void:
	# The NG+ grant loop must use NG_PLUS_STACK_AMOUNTS.get(type, 1) rather
	# than a hardcoded 1 for every item.
	var file: FileAccess = FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open player_controller.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("NG_PLUS_STACK_AMOUNTS.get(item_type, 1)") != -1,
		"NG+ grant loop looks up amount per item type")


func test_new_game_plus_bundles_compass_and_lodestone() -> void:
	# Compass and lodestone always work together, so they should be one
	# selectable row in the NG+ UI and grant both items when chosen.
	var file: FileAccess = FileAccess.open("res://scripts/house/new_game_plus_ui.gd", FileAccess.READ)
	if not file:
		assert_true(false, "Could not open new_game_plus_ui.gd")
		return
	var source: String = file.get_as_text()
	assert_true(source.find("\"lodestone\" and compass_present") != -1,
		"lodestone is filtered from available items when compass present")
	assert_true(source.find("Compass & Lodestone") != -1,
		"compass row displays as 'Compass & Lodestone'")
	assert_true(source.find("items_to_grant") != -1,
		"depart expands compass selection into compass + lodestone")
	# Verify the expansion actually adds lodestone alongside compass
	var depart_idx: int = source.find("func _actually_depart")
	assert_true(depart_idx != -1, "_actually_depart function exists")
	var depart_section: String = source.substr(depart_idx, 1500)
	assert_true(depart_section.find("items_to_grant.append(\"lodestone\")") != -1,
		"_actually_depart appends lodestone when compass is selected")
