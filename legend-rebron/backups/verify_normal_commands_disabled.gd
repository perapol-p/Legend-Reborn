extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	for stage in ["grassland","desert"]:
		data.selected_stage = stage
		var game = load("res://scenes/game_placeholder.tscn").instantiate()
		game.auto_pause_on_focus_loss = false
		game.get_node("MonsterSpawner").enabled = false
		root.add_child(game)
		current_scene = game
		await process_frame
		game.command_console.open_console()
		assert(not game.command_console.visible and not data.command_console_active)
		var combat = game.get_node("Player/Head/Camera3D/Combat")
		var before: String = combat.weapon_id
		game.command_console.submit("/weapon bow")
		game.command_console.submit("/weaponlevel")
		assert(combat.weapon_id == before and game.get_node("RunState").weapon_level() == 1)
		assert(not game.command_console.is_processing_input())
		game.free()
		await process_frame
	data.selected_stage = "practice"
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	current_scene = game
	await process_frame
	game.command_console.open_console()
	assert(game.command_console.visible)
	game.command_console.submit("/weapon bow")
	assert(game.get_node("RunState").equipped_weapon_id == "bow")
	game.command_console.close_console()
	game.free()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.command_console.open_console()
	assert(menu.command_console.visible)
	menu.command_console.close_console()
	menu.free()
	print("PASS Normal F1/open/commands blocked; Practice and lobby console retained")
	quit()
