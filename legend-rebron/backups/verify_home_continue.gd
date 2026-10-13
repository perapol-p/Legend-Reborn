extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_home_continue.save"
 data.progress_path = "user://test_home_continue_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 game.get_node("RunState").level = 4
 game.get_node("RunState").elapsed_time = 90.0
 game.get_node("MonsterSpawner").survival_time = 90.0
 var saved = load("res://scripts/run_save_codec.gd").capture(game)
 saved["stage"] = "grassland"
 assert(data.save_active_run(saved) == OK)
 game.queue_free()
 await process_frame
 await process_frame
 data.selected_stage = "grassland"
 var menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 current_scene = menu
 assert(menu.get_node("Center/Menu/Continue").visible)
 assert(menu.get_node("Center/Menu/Continue").text.contains("LV 4"))
 await process_frame
 await process_frame
 assert(menu.get_node("Center/Menu").global_position.y >= 0.0)
 assert(menu.get_node("Center/Menu").global_position.y+menu.get_node("Center/Menu").size.y <= root.get_visible_rect().size.y)
 menu.get_node("Center/Menu/Continue").pressed.emit()
 await process_frame
 await process_frame
 assert(current_scene.scene_file_path == "res://scenes/game_placeholder.tscn")
 assert(current_scene.get_node("RunState").level == 4)
 assert(current_scene.stage_id == "grassland")
 current_scene.queue_free()
 await process_frame
 await process_frame
 menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 current_scene = menu
 menu.get_node("Center/Menu/Play").pressed.emit()
 await process_frame
 await process_frame
 assert(current_scene.scene_file_path == "res://scenes/stage_select.tscn")
 print("PASS: Home with Continue fits screen; actual Continue restores run; actual Play opens existing 3-stage selection")
 current_scene.queue_free()
 await process_frame
 await process_frame
 quit()
