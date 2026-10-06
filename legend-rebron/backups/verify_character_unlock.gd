extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func press_f1() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_F1
	event.physical_keycode = KEY_F1
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = KEY_F1
	event.physical_keycode = KEY_F1
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func verify() -> void:
	var data = root.get_node("GameData")
	data.progress_path = "user://test_unlock_progress.cfg"
	data.games_completed = 0
	data.unlocked_characters.assign(["Daddy"])
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await press_f1()
	assert(menu.command_console.visible and data.command_console_active)
	menu.command_console.submit("/weapon bow")
	menu.command_console.submit("/unlock nobody")
	assert(not data.is_character_unlocked("Mommy"))
	menu.command_console.submit("/unlock mommy")
	assert(data.is_character_unlocked("Mommy"))
	data.unlocked_characters.assign(["Daddy"])
	data.load_progress()
	assert(data.is_character_unlocked("Mommy"))
	await press_f1()
	assert(not menu.command_console.visible and not data.command_console_active)
	menu.free()
	var select = load("res://scenes/character_select.tscn").instantiate()
	root.add_child(select)
	current_scene = select
	await process_frame
	assert(not select.get_node("Center/VBox/Cards/Mommy").disabled)
	assert(select.get_node("Center/VBox/Cards/Son").disabled)
	select.command_console.submit("/unlock son")
	assert(not select.get_node("Center/VBox/Cards/Son").disabled)
	select.command_console.submit("/unlock all")
	select.free()
	data.selected_character = "Mommy"
	var detail = load("res://scenes/character_detail.tscn").instantiate()
	root.add_child(detail)
	current_scene = detail
	await process_frame
	assert(detail.get_node("Center/Panel/VBox/Body/Detail").text.contains("Base weapon: Bow"))
	await press_f1()
	assert(detail.command_console.visible)
	await press_f1()
	detail.free()
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.2).timeout
	assert(game.get_node("Player/Head/Camera3D/Combat").weapon_id == "bow")
	game.command_console.open_console()
	assert(paused)
	game.command_console.submit("/unlock mommy")
	game.command_console.close_console()
	assert(not paused)
	print("PASS lobby F1, invalid commands, individual/all unlocks, saved progress, live card refresh, Mommy Archer/Bow, gameplay console")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(data.progress_path))
	quit()
