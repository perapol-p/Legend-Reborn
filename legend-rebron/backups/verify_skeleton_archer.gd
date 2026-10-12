extends SceneTree
func _initialize():
 call_deferred("verify")
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var world := Node3D.new()
 root.add_child(world)
 var env := WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color.WHITE
 env.environment.ambient_light_energy = 0.8
 world.add_child(env)
 var camera := Camera3D.new()
 world.add_child(camera)
 camera.position = Vector3(2.2,1.5,-4.0)
 camera.look_at(Vector3(0,1.0,0))
 var light := DirectionalLight3D.new()
 world.add_child(light)
 light.rotation_degrees = Vector3(-35,-30,0)
 var archer = load("res://scenes/archer_monster.tscn").instantiate()
 world.add_child(archer)
 assert(archer.archer_visual != null and archer.zombie_visual == null)
 assert(not archer.get_node("Model/Body").visible)
 assert(archer.muzzle.get_parent() == archer.archer_visual.weapon)
 archer.archer_visual.aim(0.1,0.55)
 await create_timer(0.1).timeout
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/archer_preview.png")
 print("AIM WEAPON BASIS ",archer.archer_visual.weapon.global_basis," MUZZLE ",archer.muzzle.global_position)
 archer.archer_visual.release()
 assert(archer.archer_visual.animation_player.current_animation == "Ranged_2H_Shoot")
 await create_timer(1.0).timeout
 assert(not archer.archer_visual.shooting)
 world.queue_free()
 await process_frame
 await process_frame
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_archer_run.save"
 data.progress_path = "user://test_archer_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var player = game.get_node("Player")
 player.position = Vector3(0,0.05,0)
 await physics_frame
 archer = load("res://scenes/archer_monster.tscn").instantiate()
 archer.position = Vector3(0,0.05,-8)
 archer.player = player
 archer.attack_timer = 0.0
 game.add_child(archer)
 archer.attack_timer = 0.0
 await create_timer(0.9).timeout
 assert(archer.shots_fired >= 1,"Archer must fire from attached crossbow")
 assert(archer.muzzle.global_position.distance_to(archer.global_position) < 3.0)
 var zombie = load("res://scenes/monster.tscn").instantiate()
 game.add_child(zombie)
 assert(zombie.zombie_visual != null)
 var flyer = load("res://scenes/flying_monster.tscn").instantiate()
 game.add_child(flyer)
 assert(flyer.archer_visual == null and flyer.get_node("Model/Body").visible)
 var death_time = archer.archer_visual.death_duration()
 archer.take_damage(999999)
 assert(archer.dead and archer.visible)
 assert(archer.archer_visual.animation_player.current_animation == "Death_A")
 await create_timer(death_time+0.1).timeout
 assert(not is_instance_valid(archer))
 print("PASS: Rogue rig/texture, crossbow hand mount, aim/shoot animations, actual arrow fire, death cleanup; zombie/flyer preserved")
 game.queue_free()
 await process_frame
 await process_frame
 quit()

