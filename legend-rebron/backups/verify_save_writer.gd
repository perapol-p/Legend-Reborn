extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	data.active_run_path = "user://test_cross_process_run.save"
	data.progress_path = "user://test_cross_process_progress.cfg"
	data.selected_stage = "grassland"
	data.selected_character = "Mommy"
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	current_scene = game
	var run = game.get_node("RunState")
	run.level = 10
	run.elapsed_time = 210.0
	run.damage_taken = 17.0
	run.owned_ids.assign(["pencil"])
	run.item_counts["pencil"] = 3
	run.weapon_levels["bow"] = 2
	game.get_node("MonsterSpawner").survival_time = 210.0
	game.get_node("Interface/PauseOverlay").toggle_pause()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/save_pause_menu.png")
	game.get_node("Interface/PauseOverlay").return_to_menu()
	await process_frame
	await process_frame
	assert(current_scene.name == "MainMenu" and current_scene.get_node("Center/Menu/Continue").visible)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/save_continue_menu.png")
	print("PASS wrote persisted run and displayed Save/Continue UI")
	quit()
