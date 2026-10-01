extends SceneTree
func _initialize() -> void:
	call_deferred("check_ui")
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	Input.parse_input_event(event)
	await process_frame
func check_ui() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await process_frame
	var overlay = game.get_node("Interface/PauseOverlay")
	var run = game.get_node("RunState")
	var player = game.get_node("Player")
	var crosshair = game.get_node("Interface/Crosshair")
	var data = root.get_node("GameData")
	data.settings_path = "user://tab_ui_test.cfg"
	data.restore_defaults()
	await key(KEY_ESCAPE)
	assert(paused and overlay.menu.visible and not overlay.stats_panel.visible and not overlay.equipment.visible)
	run.changed.emit()
	assert(not overlay.stats_panel.visible)
	overlay.show_settings()
	assert(overlay.stats_panel.visible and not overlay.tabs.visible)
	var settings = overlay.content.get_child(0)
	settings.show_page("Keyboard")
	settings.begin_rebind("jump")
	await key(KEY_ESCAPE)
	assert(paused and not data.rebinding_active)
	overlay.toggle_pause()
	assert(not paused and player.input_enabled)
	await key(KEY_TAB)
	assert(paused and overlay.stats_panel.visible and overlay.equipment.visible and not overlay.menu.visible)
	assert(not player.input_enabled and not crosshair.visible)
	assert(overlay.heading.text == "Stats / Primary" and overlay.content.get_child_count() == 7)
	run.equipped_weapon_id = "sword"
	run.changed.emit()
	assert(overlay.weapon_summary.text == run.weapon_name())
	assert(overlay.content.get_child(6).get_child(1).text == run.weapon_name())
	overlay.show_stats(true)
	assert(overlay.heading.text == "Stats / Secondary" and overlay.content.get_child_count() == 3)
	var id = str(run.catalog.items[0]["id"])
	run.owned_ids.append(id)
	run.item_counts[id] = 3
	run.changed.emit()
	assert(overlay.item_summary.text == "ITEMS / 3  (1 types)" and overlay.item_flow.get_child_count() == 1)
	await key(KEY_TAB)
	assert(not paused and player.input_enabled and crosshair.visible)
	run.test_level_up()
	assert(paused and not overlay.visible)
	await key(KEY_TAB)
	await key(KEY_ESCAPE)
	assert(paused and not overlay.visible)
	run.choose_item(run.offers[0])
	assert(not paused)
	await key(KEY_ESCAPE)
	assert(overlay.menu.visible and not overlay.stats_panel.visible and not overlay.equipment.visible)
	await key(KEY_TAB)
	assert(paused and not overlay.menu.visible and overlay.stats_panel.visible)
	await key(KEY_ESCAPE)
	assert(not paused and player.input_enabled)
	print("PASS: Tab stats, secondary, real weapon, item stacks, pause menu, settings, rebind, reward isolation, input restoration")
	quit()