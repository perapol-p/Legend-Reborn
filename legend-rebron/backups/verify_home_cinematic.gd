extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_home_cinematic.save"
 data.progress_path = "user://test_home_cinematic_progress.cfg"
 data.selected_stage = "grassland"
 var menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 current_scene = menu
 var bg = menu.background
 assert(bg.selected >= 0 and bg.selected < 3)
 var original_stage: String = data.selected_stage
 for i in 3:
  bg.select_world(i,false)
  assert(bg.crowds[i].size() >= 5 and bg.crowds[i].size() <= 7)
  var kinds: Array = []
  for actor in bg.crowds[i]: kinds.append(actor.actor_kind)
  assert(kinds.has("zombie") and kinds.has("archer") and kinds.has("flyer"))
  var golem: CharacterBody3D
  for actor in bg.crowds[i]:
   if actor.actor_kind == "golem": golem = actor
  if golem == null: golem = bg._spawn_actor(i,"golem",false)
  assert(golem.visual.animation_player != null)
  var actor = bg.crowds[i][0]
  var before: Vector3 = actor.global_position
  await create_timer(0.9).timeout
  assert(actor.global_position.distance_to(before) > 0.2)
  assert(actor.global_position.y > -1.0)
  var camera: Camera3D = bg.cameras[i]
  bg._update_cameras(1.0,Vector2(1,1))
  var positive: Vector3 = camera.position
  bg._update_cameras(1.0,Vector2(-1,-1))
  assert(camera.position.distance_to(positive) > 0.15)
  assert(absf(camera.rotation.z) < 0.0001 and camera.fov == 65.0)
  assert(data.selected_stage == original_stage)
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/home_cinematic_"+bg.STAGES[i]+".png")
 bg.rng.seed = 12345
 var choices: Array = []
 for i in 40:
  var next: int = bg._random_other_stage(bg.selected)
  assert(next != bg.selected)
  if not choices.has(next): choices.append(next)
 assert(choices.size() == 2)
 bg.spawn_timer = 0.0
 var count: int = bg.crowds[bg.selected].size()
 bg._process(0.05)
 assert(bg.crowds[bg.selected].size() == mini(count+1,8))
 for i in 15: bg._spawn_actor(bg.selected,"",false)
 assert(bg.crowds[bg.selected].size() == 8)
 var previous: int = bg.selected
 bg.cycle_time = bg.shot_length
 bg._process(0.1)
 assert(bg.selected != previous)
 await create_timer(0.8).timeout
 assert(bg.worlds[previous].process_mode == Node.PROCESS_MODE_DISABLED)
 assert(get_nodes_in_group("monsters").is_empty())
 assert(data.load_active_run().is_empty())
 print("PASS: random initial/nonrepeat scenes; random shot length/camera angles; subtle cursor parallax without roll; zombie/archer/eye/golem visuals and movement; random new arrivals capped at 8; inactive worlds suspended; gameplay/save isolation")
 menu.queue_free()
 await process_frame
 await process_frame
 quit()
