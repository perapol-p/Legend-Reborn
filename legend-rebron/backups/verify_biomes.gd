extends SceneTree
func _initialize():
 call_deferred("verify")
func verify():
 create_timer(40.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_biomes_run.save"
 data.progress_path = "user://test_biomes_progress.cfg"
 for stage in ["grassland","desert"]:
  data.selected_stage = stage
  var game = load("res://scenes/game_placeholder.tscn").instantiate()
  game.auto_pause_on_focus_loss = false
  game.get_node("MonsterSpawner").enabled = false
  root.add_child(game)
  current_scene = game
  var arena = game.get_node("Arena")
  var player = game.get_node("Player")
  player.set_physics_process(false)
  player.get_node("Head/Camera3D/Combat").view.hide()
  assert(arena.get_node_or_null("Floor") == null)
  assert(arena.get_node("BiomeLandscape/RollingTerrain") != null)
  assert(arena.obstacle_points.size() >= 30)
  assert(arena.ground_height(0,12) == 0.0)
  assert(arena.ground_height(40,25) > 2.0)
  await physics_frame
  await physics_frame
  # Terrain ray hits must match rendered heights and permit the existing spawner.
  for point in [Vector2(0,0),Vector2(-34,-22),Vector2(40,25),Vector2(22,-40),Vector2(60,60)]:
   var expected: float = arena.ground_height(point.x,point.y)
   var ray := PhysicsRayQueryParameters3D.create(Vector3(point.x,expected+8,point.y),Vector3(point.x,-5,point.y),1)
   var hit: Dictionary = arena.get_world_3d().direct_space_state.intersect_ray(ray)
   assert(not hit.is_empty(),stage+" terrain ray miss")
   # Props may be hit first; the natural ground must at least exist underneath.
   assert(hit.position.y >= expected-0.02)
   if hit.collider.name == "RollingTerrain": assert(hit.normal.y > 0.8)
  var spawner = game.get_node("MonsterSpawner")
  for kind in ["melee","archer","flyer"]:
   var enemy = spawner.spawn_one(false,kind,true)
   assert(enemy != null,stage+" spawn "+kind)
   assert(enemy.global_position.y >= arena.ground_height(enemy.position.x,enemy.position.z))
  var camera := Camera3D.new()
  camera.name = "MapPreviewCamera"
  game.add_child(camera)
  camera.current = true
  camera.fov = 72.0
  camera.position = Vector3(0,2.0,12)
  camera.look_at(Vector3(-15,3,-24) if stage == "grassland" else Vector3(24,3,-24))
  await create_timer(0.25).timeout
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/"+stage+"_biome_fps.png")
   camera.position = Vector3(58,76,80)
   camera.look_at(Vector3(0,1,0))
   await RenderingServer.frame_post_draw
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/"+stage+"_biome_overview.png")
  # Old saves below a newly raised hill are safely placed above the terrain.
  player.position = Vector3(40,0,25)
  arena.ensure_actor_clearance(player)
  assert(player.position.y >= arena.ground_height(40,25)+0.05)
    # Walk up a real hill through the controller, checking collision contact.
  for actor in spawner.monsters: actor.queue_free()
  player.position = Vector3(23,arena.ground_height(23,25)+0.07,25)
  player.rotation.y = 0.0
  player.velocity = Vector3.ZERO
  player.set_physics_process(true)
  Input.action_press("move_right")
  await create_timer(0.9).timeout
  Input.action_release("move_right")
  assert(player.position.x > 27.0,stage+" player stuck on hill")
  assert(player.position.y >= arena.ground_height(player.position.x,player.position.z)-0.15,stage+" fell through terrain")
  assert(player.is_on_floor(),stage+" lost hill contact")
  player.set_physics_process(false)
  print("PASS ",stage," terrain, slopes, spawn all enemy types, save clearance; obstacle count ",arena.obstacle_points.size()," batches ",arena.batches.size())
  game.queue_free()
  await process_frame
  await process_frame
  paused = false
 data.selected_stage = "practice"
 var practice = load("res://scenes/game_placeholder.tscn").instantiate()
 practice.auto_pause_on_focus_loss = false
 root.add_child(practice)
 assert(practice.get_node("Arena/Floor") != null)
 assert(practice.get_node("Arena/Terrain") != null)
 print("PASS Practice retains original grid, ramps and pyramids")
 practice.queue_free()
 await process_frame
 await process_frame
 quit()
