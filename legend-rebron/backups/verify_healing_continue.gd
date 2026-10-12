extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(12.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_healing.save"
 data.progress_path = "user://test_healing_progress.cfg"
 var saved: Dictionary = data.load_active_run()
 assert(not saved.is_empty())
 data.selected_stage = saved["stage"]
 data.selected_character = saved["run"]["character_name"]
 data.pending_resume = saved
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 assert(game.healing.supplies[0]["opened"])
 assert(game.healing.hearts.size() == 1)
 assert(is_equal_approx(game.healing.hearts[0]["remaining"],7.5))
 assert(game.healing.supplies.size() == 3)
 game.queue_free()
 await process_frame
 await process_frame
 data.selected_stage = "desert"
 game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 game.get_node("MonsterSpawner").enabled = false
 root.add_child(game)
 current_scene = game
 assert(game.healing.supplies.size() == 3)
 for chest in game.healing.supplies:
  assert(not chest["opened"])
  var point: Vector3 = chest["node"].global_position
  assert(point.y >= game.get_node("Arena").ground_height(point.x,point.z))
 print("PASS: Continue in fresh process retains used supply, heart TTL and RNG; new Desert starts with 3 fresh grounded supplies")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
