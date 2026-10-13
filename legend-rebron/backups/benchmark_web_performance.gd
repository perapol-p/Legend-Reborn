extends SceneTree
func _initialize(): call_deferred("benchmark")
func benchmark():
 var data = root.get_node("GameData")
 data.active_run_path = "user://benchmark_web_run.save"
 data.progress_path = "user://benchmark_web_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 var start := Time.get_ticks_usec()
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.auto_pause_on_focus_loss = false
 game.get_node("RunState").catalog.data["base_stats"]["max_hp"] = 1000000
 var player = game.get_node("Player")
 player.set_physics_process(false)
 player.position = Vector3(0,0.04,0)
 var spawner = game.get_node("MonsterSpawner")
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.set_physics_process(false)
 for i in 160:
  var actor = load("res://scenes/monster.tscn").instantiate()
  actor.player = player
  actor.position = Vector3((i%16-8)*3.0,0.04,(i/16-5)*3.0)
  actor.max_health = 100000
  spawner.add_child(actor)
  spawner.monsters.append(actor)
 for point in [Vector3(3,1,3),Vector3(-3,1,3),Vector3(3,1,-3),Vector3(-3,1,-3)]:
  var vortex = combat.spawn_tornado(point,1,3.5,30)
 print("LOAD_MS ",float(Time.get_ticks_usec()-start)/1000.0)
 for actor in spawner.monsters: actor.set_physics_process(false)
 for vortex in get_nodes_in_group("weapon_tornadoes"): vortex.set_physics_process(false)
 for i in 25: await physics_frame
 var total := 0.0
 var peak := 0.0
 for i in 90:
  await physics_frame
  var begin := Time.get_ticks_usec()
  for actor in spawner.monsters: actor._physics_process(1.0/60.0)
  for vortex in get_nodes_in_group("weapon_tornadoes"): vortex._physics_process(1.0/60.0)
  var time := float(Time.get_ticks_usec()-begin)/1000.0
  total += time
  peak = maxf(peak,time)
 print("AI_AND_VORTEX_MS_AVG ",total/90.0," PEAK ",peak)
 print("STATIC_MEMORY_MB ",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
 print("NODES ",Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
 print("BENCHMARK 160 zombies + 4 tornadoes; no enemy cap")
 game.queue_free()
 await process_frame
 quit()
