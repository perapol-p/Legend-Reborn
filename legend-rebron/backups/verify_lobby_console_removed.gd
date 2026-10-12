extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	for path in ["main_menu","stage_select","character_select","character_detail"]:
		var scene = load("res://scenes/" + path + ".tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await process_frame
		var event := InputEventKey.new()
		event.physical_keycode = KEY_F1
		event.keycode = KEY_F1
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		assert(not data.command_console_active)
		assert(scene.find_children("*","RichTextLabel",true,false).is_empty())
		scene.free()
		await process_frame
	data.selected_stage = "practice"
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	current_scene = game
	await process_frame
	game.command_console.open_console()
	assert(game.command_console.visible and data.command_console_active)
	game.command_console.close_console()
	game.practice_ui.open_panel()
	assert(game.practice_ui.visible)
	game.free()
	print("PASS F1 removed from all four lobby screens; Practice console and U tools retained")
	quit()
