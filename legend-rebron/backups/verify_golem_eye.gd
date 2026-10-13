extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(25.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_golem_eye.save"
 data.progress_path = "user://test_golem_eye_progress.cfg"
 var world := Node3D.new()
 root.add_child(world)
 var environment := WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color = Color.WHITE
 environment.environment.ambient_light_energy = 0.6
 world.add_child(environment)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-35,-30,0)
 world.add_child(light)
 var camera := Camera3D.new()
 world.add_child(camera)
 for kind in ["boss","flyer"]:
  var actor = load("res://scenes/boss.tscn" if kind=="boss" else "res://scenes/flying_monster.tscn").instantiate()
  world.add_child(actor)
  assert(not actor.get_node("Model/Body").visible)
  var visual = actor.golem_visual if kind=="boss" else actor.flyer_visual
  assert(visual != null and actor.death_visual == visual)
  assert(visual.animation_player.current_animation == ("Idle" if kind=="boss" else "fly"))
  camera.position = Vector3(0,2.8,-8) if kind=="boss" else Vector3(0,1.6,-5)
  camera.look_at(Vector3(0,1.8,0) if kind=="boss" else Vector3(0,1.2,0))
  await create_timer(0.25).timeout
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/"+kind+"_replacement_preview.png")
  if kind=="boss":
   assert(actor.max_health == 10000.0)
   assert(is_equal_approx(actor.get_node("Collision").shape.radius,0.65))
  else:
   assert(actor.wings.is_empty())
   assert(actor.muzzle.position == Vector3(0,1.25,-0.5))
  actor.queue_free()
  await process_frame
 world.queue_free()
 await process_frame
 await process_frame
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var player = game.get_node("Player")
 player.set_physics_process(false)
 player.position = Vector3(0,0.05,0)
 game.get_node("RunState").set_physics_process(false)
 var flyer = load("res://scenes/flying_monster.tscn").instantiate()
 flyer.player = player
 flyer.position = Vector3(0,2.2,-5)
 game.add_child(flyer)
 flyer.attack_timer = 0.0
 await create_timer(0.9).timeout
 assert(flyer.shots_fired >= 1)
 assert(flyer.flyer_visual.animation_player.current_animation == "fly")
 var boss = load("res://scenes/boss.tscn").instantiate()
 boss.player = player
 boss.position = Vector3(0,0.05,-2.7)
 game.add_child(boss)
 boss.attack_timer = 0.0
 var hp: float = game.get_node("RunState").current_health()
 await create_timer(0.1).timeout
 assert(game.get_node("RunState").current_health() < hp,"Golem must still damage player")
 assert(boss.golem_visual.attacking)
 assert(boss.golem_visual.animation_player.current_animation == "Attack3")
 var zombie = load("res://scenes/monster.tscn").instantiate()
 game.add_child(zombie)
 assert(zombie.zombie_visual != null and zombie.melee_visual == zombie.zombie_visual)
 var archer = load("res://scenes/archer_monster.tscn").instantiate()
 game.add_child(archer)
 assert(archer.archer_visual != null and archer.flyer_visual == null)
 flyer.take_damage(999999)
 assert(flyer.dead and flyer.collision_layer == 0)
 boss.take_damage(999999)
 assert(boss.dead and boss.collision_layer == 0)
 await create_timer(1.0).timeout
 assert(not is_instance_valid(flyer) and not is_instance_valid(boss))
 game.queue_free()
 await process_frame
 await process_frame
 # Normal boss timing and victory callback remain intact.
 data.selected_stage = "grassland"
 game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 game.get_node("MonsterSpawner").enabled = false
 root.add_child(game)
 current_scene = game
 var spawner = game.get_node("MonsterSpawner")
 assert(spawner.survival_duration == 900.0 and spawner.flyer_unlock_time == 600.0)
 await physics_frame
 await physics_frame
 spawner.enabled = true
 spawner.boss_phase = true
 spawner.survival_time = 900.0
 spawner._try_spawn_boss()
 assert(is_instance_valid(spawner.boss) and spawner.boss.golem_visual != null)
 spawner.boss.take_damage(999999)
 await process_frame
 await process_frame
 assert(game.round_won and game.get_node("RunState").finished)
 print("PASS: textured/animated Golem boss and Flying Eye, aligned muzzle, melee/fireball combat, death cleanup; zombie/archer preserved; 15min boss and 10min flyer timing; boss victory callback")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
