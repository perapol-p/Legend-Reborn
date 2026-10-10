extends SceneTree
func _initialize(): call_deferred("verify")
func aim_at_supply(player, healing, index: int):
 var chest = healing.supplies[index]["node"]
 player.global_position = chest.global_position+Vector3(0,0.1,2.2)
 player.camera.look_at(chest.global_position+Vector3.UP*0.5)
 await physics_frame
 await physics_frame
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_supply_refill.save"
 data.progress_path = "user://test_supply_refill_progress.cfg"
 data.selected_stage = "grassland"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 game.get_node("MonsterSpawner").enabled = false
 root.add_child(game)
 current_scene = game
 var run = game.get_node("RunState")
 var player = game.get_node("Player")
 var healing = game.healing
 run.set_physics_process(false)
 player.set_physics_process(false)
 healing.set_physics_process(false)
 assert(healing.supplies.size() == 3)
 await aim_at_supply(player,healing,0)
 run.damage_taken = 0.0
 assert(healing.open_supply(0) == 0.0 and healing.supplies[0]["cooldown"] == 0.0)
 run.damage_taken = 80.0
 assert(healing.open_supply(0) == 20.0)
 assert(healing.supplies[0]["cooldown"] == 180.0)
 assert(healing.supplies[0]["label"].text == "REFILLS IN 03:00")
 assert(healing.open_supply(0) == 0.0)
 healing._advance_supplies(60.0)
 assert(healing.supplies[0]["cooldown"] == 120.0)
 assert(healing.supplies[1]["cooldown"] == 0.0)
 assert(healing.supplies[0]["label"].text == "REFILLS IN 02:00")
 await aim_at_supply(player,healing,1)
 assert(healing.open_supply(1) == 20.0)
 healing._advance_supplies(29.5)
 assert(healing.supplies[0]["cooldown"] == 90.5)
 assert(healing.supplies[1]["cooldown"] == 150.5)
 paused = true
 healing._advance_supplies(180.0)
 assert(healing.supplies[0]["cooldown"] == 90.5)
 paused = false
 run.finished = true
 healing._advance_supplies(180.0)
 assert(healing.supplies[0]["cooldown"] == 90.5)
 run.finished = false
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 assert(data.save_active_run(saved) == OK)
 var loaded: Dictionary = data.load_active_run()
 game.queue_free()
 await process_frame
 await process_frame
 data.pending_resume = loaded
 game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 run = game.get_node("RunState")
 player = game.get_node("Player")
 healing = game.healing
 run.set_physics_process(false)
 player.set_physics_process(false)
 healing.set_physics_process(false)
 assert(healing.supplies[0]["cooldown"] == 90.5)
 assert(healing.supplies[1]["cooldown"] == 150.5)
 assert(healing.supplies[0]["label"].text == "REFILLS IN 01:31")
 healing._advance_supplies(90.5)
 assert(not healing.supplies[0]["opened"])
 assert(healing.supplies[0]["label"].text == "SUPPLIES")
 assert(healing.supplies[1]["cooldown"] == 60.0)
 healing._advance_supplies(1200.0)
 assert(healing.supplies[0]["cooldown"] == 0.0)
 await aim_at_supply(player,healing,0)
 run.damage_taken = 70.0
 assert(healing.open_supply(0) == 20.0)
 assert(healing.supplies[0]["cooldown"] == 180.0)
 assert(healing.open_supply(0) == 0.0)
 var legacy: Dictionary = healing.capture_state()
 legacy.erase("cooldowns")
 healing.restore_state(legacy)
 assert(healing.supplies[0]["cooldown"] == 180.0)
 assert(healing.supplies[1]["cooldown"] == 0.0)
 print("PASS: 3 independent refill timers, 20 percent healing, 180 seconds after use, countdown labels, ready reuse/no stacking, pause/end/full HP guards, Continue preserves exact remaining times, legacy save migration")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
