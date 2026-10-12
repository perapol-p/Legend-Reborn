extends SceneTree
func _initialize():
 call_deferred("verify")
func verify():
 var world := Node3D.new()
 root.add_child(world)
 var environment := WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color = Color.WHITE
 environment.environment.ambient_light_energy = 0.8
 world.add_child(environment)
 var camera := Camera3D.new()
 world.add_child(camera)
 camera.position = Vector3(0, 1.2, -4)
 camera.look_at(Vector3(0, 0.95, 0))
 var light := DirectionalLight3D.new()
 world.add_child(light)
 light.rotation_degrees = Vector3(-40, -30, 0)
 var zombie = load("res://scenes/monster.tscn").instantiate()
 world.add_child(zombie)
 assert(zombie.zombie_visual != null)
 assert(not zombie.get_node("Model/Body").visible)
 var visuals = zombie.zombie_visual
 visuals.get_node("ZombieAsset").rotation.y = 0.0
 visuals.update_locomotion(true,2.6)
 await create_timer(0.35).timeout
 if not DisplayServer.get_name() == "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/zombie_preview.png")
 assert(visuals.animation_player.current_animation == "Armature|Walk")
 visuals.attack()
 assert(visuals.animation_player.current_animation == "Armature|Attack")
 await create_timer(1.05).timeout
 assert(not visuals.attacking)
 for path in ["res://scenes/archer_monster.tscn", "res://scenes/flying_monster.tscn", "res://scenes/boss.tscn"]:
  var other = load(path).instantiate()
  world.add_child(other)
  assert(other.zombie_visual == null)
  assert(other.get_node("Model/Body").visible)
  other.queue_free()
 var kills := [0]
 zombie.defeated.connect(func(): kills[0] += 1)
 assert(zombie.take_damage(999999.0) == 2)
 assert(zombie.dead and zombie.visible)
 assert(visuals.animation_player.current_animation == "Armature|Death")
 assert(zombie.take_damage(1) == 0 and kills[0] == 1)
 await create_timer(0.95).timeout
 assert(not is_instance_valid(zombie))
 print("PASS: zombie texture/model, walk, attack, death, single kill credit; ranged/flyer/boss preserved")
 world.queue_free()
 await process_frame
 quit()