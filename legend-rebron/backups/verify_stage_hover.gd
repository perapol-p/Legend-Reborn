extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_stage_hover.save"
 data.progress_path = "user://test_stage_hover_progress.cfg"
 data.selected_stage = "grassland"
 var page = load("res://scenes/stage_select.tscn").instantiate()
 root.add_child(page)
 current_scene = page
 assert(not page.background.auto_cycle)
 for i in 3:
  var stage: String = data.STAGES[i]
  page.stage_buttons[stage].mouse_entered.emit()
  assert(page.background.selected == i)
  assert(data.selected_stage == "grassland","Hover must not choose gameplay stage")
  await create_timer(0.35).timeout
  assert(page.background.views[i].render_target_update_mode == SubViewport.UPDATE_ALWAYS)
  assert(page.background.images[i].modulate.a == 1.0)
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/stage_hover_"+stage+".png")
 page.background._process(30.0)
 assert(page.background.selected == 2,"Hovered map must not be changed by Home auto cycle")
 page.stage_buttons["desert"].focus_entered.emit()
 assert(page.background.selected == 1)
 page.stage_buttons["desert"].pressed.emit()
 await process_frame
 await process_frame
 assert(data.selected_stage == "desert")
 assert(current_scene.scene_file_path == "res://scenes/character_select.tscn")
 print("PASS: mouse hover/focus previews matching 3 maps, quick crossfade, no auto cycle or stage mutation on hover; clicking still selects stage and opens character selection")
 current_scene.queue_free()
 await process_frame
 await process_frame
 quit()
