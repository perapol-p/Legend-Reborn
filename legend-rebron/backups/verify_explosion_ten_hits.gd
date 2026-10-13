extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(15,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_explosion_ten_hits.save"
 data.progress_path = "user://test_explosion_ten_hits_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.auto_pause_on_focus_loss = false
 var player = game.get_node("Player")
 player.set_physics_process(false)
 player.position = Vector3.ZERO
 player.rotation = Vector3.ZERO
 player.head.rotation = Vector3(-0.12,0,0)
 var run = game.get_node("RunState")
 run.set_physics_process(false)
 run.weapon_levels["spellbook"] = 5
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.set_physics_process(false)
 assert(combat.try_explosion())
 var effect = get_nodes_in_group("staff_explosions")[0]
 effect.set_physics_process(false)
 var target = load("res://scenes/monster.tscn").instantiate()
 target.max_health = 10000
 target.position = effect.position+Vector3(4,0,0)
 game.add_child(target)
 target.set_physics_process(false)
 game.get_node("MonsterSpawner").monsters.append(target)
 var outside = load("res://scenes/monster.tscn").instantiate()
 outside.max_health = 10000
 outside.position = effect.position+Vector3(36,0,0)
 game.add_child(outside)
 outside.set_physics_process(false)
 game.get_node("MonsterSpawner").monsters.append(outside)
 await physics_frame
 effect.age = 2.9
 effect._physics_process(0.09)
 assert(effect.hits_done==0 and target.health==10000)
 effect._physics_process(0.02)
 assert(effect.hits_done==1)
 var total: float = effect.damage
 assert(is_equal_approx(10000.0-target.health,total/10.0))
 assert(player.shake_remaining>0.0)
 player.clear_camera_shake()
 for i in 3:
  player.clear_camera_shake()
  effect._physics_process(0.18001)
  assert(is_equal_approx(player.shake_remaining,0.16),"Every pulse must shake")
 assert(effect.hits_done==4)
 assert(is_equal_approx(10000.0-target.health,total*0.4))
 assert(is_equal_approx(player.shake_remaining,0.16))
 assert(outside.health==10000)
 # Continue partway through the attack must deliver only its remaining six hits.
 var codec = load("res://scripts/run_save_codec.gd")
 var saved: Dictionary = codec.capture(game)
 assert(saved["staff_explosions"][0]["hits_done"]==4)
 effect.queue_free()
 target.queue_free()
 outside.queue_free()
 await process_frame
 codec.restore_world(game,saved)
 effect = get_nodes_in_group("staff_explosions")[0]
 effect.set_physics_process(false)
 assert(effect.hits_done==4)
 target = null
 outside = null
 for actor in get_nodes_in_group("monsters"):
  actor.set_physics_process(false)
  if actor.global_position.distance_to(effect.global_position) < 10: target=actor
  else: outside=actor
 for i in 6:
  player.clear_camera_shake()
  effect._physics_process(0.18001)
  assert(is_equal_approx(player.shake_remaining,0.16),"Resumed hits must shake")
 assert(effect.hits_done==10)
 assert(is_equal_approx(10000.0-target.health,total),"All ten hits sum to original total damage")
 assert(outside.health==10000)
 var health: float = target.health
 effect._physics_process(0.1)
 assert(effect.hits_done==10 and target.health==health,"No eleventh hit")
 # Check backwards compatibility with a completed single-hit save.
 saved = codec.capture(game)
 saved["staff_explosions"][0].erase("hits_done")
 effect.queue_free()
 target.queue_free()
 outside.queue_free()
 await process_frame
 codec.restore_world(game,saved)
 effect = get_nodes_in_group("staff_explosions")[0]
 effect.set_physics_process(false)
 assert(effect.hits_done==10)
 effect._physics_process(0.1)
 assert(effect.hits_done==10)
 print("PASS: 3s charge, ten timed hits, unchanged total damage, range, shake on every hit, resume after 4 hits, no extra hits and legacy save safety")
 quit()
