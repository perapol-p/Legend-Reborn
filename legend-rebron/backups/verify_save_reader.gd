extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	data.active_run_path = "user://test_cross_process_run.save"
	data.progress_path = "user://test_cross_process_progress.cfg"
	var saved: Dictionary = data.load_active_run()
	assert(saved["run"]["level"] == 10 and saved["stage"] == "grassland")
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.continue_run()
	await process_frame
	await process_frame
	var game = current_scene
	var run = game.get_node("RunState")
	assert(game.stage_id == "grassland" and run.character_name == "Mommy" and run.level == 10)
	assert(run.stack_count("pencil") == 3 and run.weapon_level("bow") == 2)
	assert(run.elapsed_time >= 210.0 and run.elapsed_time < 211.0)
	assert(run.current_health() == 83.0)
	game.free()
	data.clear_active_run()
	print("PASS fresh process loads Continue with stage/character/level/time/items/weapon/health intact")
	quit()
