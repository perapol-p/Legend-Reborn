extends SceneTree
func _initialize():
 call_deferred("verify")
func verify():
 create_timer(20.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_healing.save"
 data.progress_path = "user://test_healing_progress.cfg"
 data.selected_stage = "grassland"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 game.get_node("MonsterSpawner").enabled = false
 root.add_child(game)
 current_scene = game
 var run = game.get_node("RunState")
 var player = game.get_node("Player")
 var combat = player.get_node("Head/Camera3D/Combat")
 var healing = game.healing
 run.set_physics_process(false)
 player.set_physics_process(false)
 healing.set_physics_process(false)
 assert(healing.supplies.size() == 3)
 assert(is_equal_approx(healing.drop_chance(),0.03))
 run.damage_taken = 71.0
 assert(is_equal_approx(healing.drop_chance(),0.06))
 run.damage_taken = 70.0
 assert(is_equal_approx(healing.drop_chance(),0.03))
 run.damage_taken = 0.0
 var heart_node = healing.spawn_heart(player.global_position)
 var entry: Dictionary = healing.hearts[0]
 assert(healing.collect_heart(entry) == 0.0 and healing.hearts.size() == 1)
 run.damage_taken = 50.0
 assert(is_equal_approx(healing.collect_heart(entry),8.0))
 assert(is_equal_approx(run.current_health(),58.0) and healing.hearts.is_empty())
 run.catalog.data["base_stats"]["max_hp"] = 500.0
 run.damage_taken = 300.0
 healing.spawn_heart(player.global_position)
 assert(is_equal_approx(healing.collect_heart(healing.hearts[0]),40.0))
 assert(is_equal_approx(run.current_health(),240.0))
 run.damage_taken = 1.0
 healing.spawn_heart(player.global_position)
 assert(is_equal_approx(healing.collect_heart(healing.hearts[0]),1.0))
 assert(run.current_health() == 500.0)
 run.catalog.data["base_stats"]["max_hp"] = 100.0
 healing.spawn_heart(player.global_position+Vector3(10,0,0),3.0)
 paused = true
 var lifetime: float = healing.hearts[0]["remaining"]
 await process_frame
 await process_frame
 assert(healing.hearts[0]["remaining"] == lifetime)
 assert(run.heal_fraction(0.2) == 0.0)
 paused = false
 healing._physics_process(3.1)
 assert(healing.hearts.is_empty())
 # Supply requires range, aim and line of sight; full HP does not consume it.
 var chest = healing.supplies[0]["node"]
 player.global_position = chest.global_position+Vector3(0,0,2.0)
 player.camera.look_at(chest.global_position+Vector3.UP*0.5)
 await physics_frame
 await physics_frame
 assert(healing.open_supply(0) == 0.0 and not healing.supplies[0]["opened"])
 run.damage_taken = 60.0
 assert(is_equal_approx(healing.open_supply(0),20.0))
 assert(healing.open_supply(0) == 0.0 and run.current_health() == 60.0)
 assert(healing.open_supply(1) == 0.0)
 # A real monster kill emits exactly one drop roll; repeat damage cannot farm it.
 var trial := RandomNumberGenerator.new()
 for seed_value in 1000:
  trial.seed = seed_value
  if trial.randf() < 0.03:
   healing.rng.seed = seed_value
   break
 var monster = load("res://scenes/monster.tscn").instantiate()
 monster.position = Vector3(10,0.1,10)
 game.add_child(monster)
 combat.deal_hit(monster,999999)
 assert(healing.hearts.size() == 1)
 var rng_after: int = healing.rng.state
 combat.deal_hit(monster,999999)
 assert(healing.hearts.size() == 1 and healing.rng.state == rng_after)
 healing.hearts[0]["remaining"] = 7.5
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 assert(saved["healing"]["opened"][0])
 assert(saved["healing"]["hearts"][0]["remaining"] == 7.5)
 assert(data.save_active_run(saved) == OK)
 var loaded: Dictionary = data.load_active_run()
 assert(not loaded.is_empty())
 healing.supplies[0]["opened"] = false
 codec.restore_world(game,loaded)
 assert(healing.supplies[0]["opened"] and healing.hearts.size() == 1)
 assert(healing.hearts[0]["remaining"] == 7.5 and healing.rng.state == rng_after)
 run.finished = true
 assert(run.heal_fraction(1.0) == 0.0 and healing.open_supply(1) == 0.0)
 run.finished = false
 print("PASS: 3/6 percent drop chance; real kill single roll; 8 percent heal scales/caps; full HP retains drops/chest; expiration/pause/death guards; 3 one-use 20 percent supplies; disk-save restores used chest, heart TTL and RNG")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
