extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_home_only.save"
 data.progress_path = "user://test_home_only_progress.cfg"
 data.selected_stage = "grassland"
 var menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 current_scene = menu
 var background = menu.background
 assert(background.views.size() == 3 and background.zombies.size() == 12)
 assert(not menu.get_node("Center/Menu/Continue").visible)
 assert(menu.get_node("Center/Menu/Play").pressed.is_connected(menu.get_node("Center/Menu/Play").pressed.get_connections()[0].callable))
 assert(background.worlds[0].get_world_3d() != background.worlds[1].get_world_3d())
 assert(background.worlds[1].process_mode == Node.PROCESS_MODE_DISABLED)
 var original_stage: String = data.selected_stage
 for i in 3:
  background.select_world(i,false)
  assert(background.selected == i)
  assert(background.views[i].render_target_update_mode == SubViewport.UPDATE_ALWAYS)
  assert(data.selected_stage == original_stage)
  var npc = background.zombies[i*4]
  var initial: Vector3 = npc.global_position
  await create_timer(0.9).timeout
  assert(npc.global_position.distance_to(initial) > 0.4,"Menu zombie must walk in stage "+str(i))
  assert(npc.global_position.y > -1.0,"Zombie must stay above floor")
  assert(npc.visual.animation_player.current_animation == "Armature|Walk")
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/home_"+background.STAGES[i]+"_preview.png")
 background.cycle_time = 12.0
 background._process(0.1)
 assert(background.selected == 0)
 await create_timer(0.8).timeout
 assert(background.worlds[1].process_mode == Node.PROCESS_MODE_DISABLED)
 assert(not data.load_active_run().has("run"))
 menu.get_node("QuitDialog").popup_centered()
 assert(menu.get_node("QuitDialog").visible)
 menu.get_node("QuitDialog").hide()
 # No combat/spawning or player state exists in these background worlds.
 assert(get_nodes_in_group("monsters").is_empty())
 print("PASS: all 3 real map previews, independent worlds, walking animated zombies on each map, idle-world rendering/processing disabled, 12s auto cycle/manual selection, menu input and save isolation")
 menu.queue_free()
 await process_frame
 await process_frame
 quit()
