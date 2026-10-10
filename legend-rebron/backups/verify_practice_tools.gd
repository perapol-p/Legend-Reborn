extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
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
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func verify() -> void:
	var data = root.get_node("GameData")
	data.selected_stage = "practice"
	data.progress_path = "user://test_practice_tools_progress.cfg"
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.2).timeout
	paused = false
	game.get_node("Interface/PauseOverlay").hide()
	var tools = game.practice_ui
	assert(is_instance_valid(tools) and not tools.visible)
	await key(KEY_U)
	assert(tools.visible and paused and data.practice_ui_active)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not game.get_node("Player").input_enabled)
	assert(tools.buttons.size() == 24)
	tools.count.value = 3
	tools.buttons["/spawn archer"].pressed.emit()
	assert(game.get_node("MonsterSpawner").monsters.size() == 3)
	tools.buttons["/weapon bow"].pressed.emit()
	var run = game.get_node("RunState")
	assert(run.equipped_weapon_id == "bow")
	tools.buttons["/weaponlevel"].pressed.emit()
	assert(run.weapon_level() == 2)
	tools.buttons["/hit"].pressed.emit()
	tools.buttons["/kill"].pressed.emit()
	assert(game.get_node("Combo").points == 4)
	tools.buttons["/reset"].pressed.emit()
	assert(game.get_node("Combo").points == 0)
	tools.buttons["/spawndebug on"].pressed.emit()
	assert(game.get_node("MonsterSpawner").ring.visible)
	tools.buttons["/spawndebug off"].pressed.emit()
	assert(not game.get_node("MonsterSpawner").ring.visible)
	tools.buttons["/spawninfo"].pressed.emit()
	assert(tools.output.text.contains("Alive:"))
	tools.buttons["/help"].pressed.emit()
	assert(tools.output.text.contains("/weaponlevel"))
	tools.buttons["/clear"].pressed.emit()
	assert(tools.output.text == "Output cleared.")
	tools.buttons["/unlock all"].pressed.emit()
	assert(data.is_character_unlocked("Mommy") and data.is_character_unlocked("Son"))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/practice_tools_ui.png")
	await key(KEY_ESCAPE)
	assert(not tools.visible and not paused and not data.practice_ui_active)
	assert(not game.get_node("Interface/PauseOverlay").visible)
	await key(KEY_U)
	tools.buttons["/levelup"].pressed.emit()
	assert(not tools.visible and paused and not run.offers.is_empty())
	assert(game.get_node("Interface/RewardOverlay").visible)
	run.choose_item(run.offers[0])
	assert(not paused)
	await key(KEY_U)
	await key(KEY_F1)
	assert(not tools.visible and game.command_console.visible and paused)
	await key(KEY_ESCAPE)
	assert(not game.command_console.visible and not paused)
	await key(KEY_U)
	await key(KEY_U)
	assert(not tools.visible and not paused)
	assert(data.rebind("jump",KEY_U).contains("reserved"))
	print("PASS U modal, all 24 command buttons, spawn count, weapon/levels/combo/debug/unlock/help/clear, item choice, Esc, F1 and cursor safety")
	game.get_node("Player").receive_damage(10000.0)
	await process_frame
	await process_frame
	assert(game.result_overlay.visible and not tools.visible and not game.practice_hint.visible)
	assert(not data.practice_ui_active)
	game.free()
	assert(not data.practice_ui_active and not paused)
	data.selected_stage = "grassland"
	var normal = load("res://scenes/game_placeholder.tscn").instantiate()
	normal.auto_pause_on_focus_loss = false
	normal.get_node("MonsterSpawner").enabled = false
	root.add_child(normal)
	current_scene = normal
	await process_frame
	assert(not is_instance_valid(normal.practice_ui))
	await key(KEY_U)
	assert(not data.practice_ui_active)
	normal.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(data.progress_path))
	print("PASS tools restricted to Practice, exit resets modal state")
	await process_frame
	quit()


