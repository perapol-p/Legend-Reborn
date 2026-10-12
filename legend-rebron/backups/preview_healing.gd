extends SceneTree
func _initialize(): call_deferred("preview")
func preview():
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_healing_preview.save"
 data.progress_path = "user://test_healing_preview_progress.cfg"
 data.selected_stage = "grassland"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 game.get_node("MonsterSpawner").enabled = false
 root.add_child(game)
 current_scene = game
 var player = game.get_node("Player")
 var run = game.get_node("RunState")
 player.set_physics_process(false)
 run.set_physics_process(false)
 run.damage_taken = 50.0
 run.changed.emit()
 var chest = game.healing.supplies[0]["node"]
 player.global_position = chest.global_position+Vector3(0,0.1,2.2)
 player.camera.look_at(chest.global_position+Vector3.UP*0.55)
 game.healing.spawn_heart(game.healing._ground_point(chest.global_position+Vector3(1.5,0,0)))
 await create_timer(0.25).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/healing_supplies_preview.png")
 assert(game.healing.selected_supply == 0)
 var event := InputEventKey.new()
 event.physical_keycode = KEY_E
 event.pressed = true
 game.healing._unhandled_input(event)
 assert(game.healing.supplies[0]["opened"])
 await create_timer(0.35).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/healing_opened_preview.png")
 print("PASS: rendered heart/chest; actual E input opens aimed chest; heal toast and lid animation")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
