extends SceneTree
func _initialize(): call_deferred("verify")
func shot(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 image.save_png("res://backups/"+name+".png")
 return image
func verify():
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_ui_final.save"
 data.progress_path = "user://test_ui_final_progress.cfg"
 data.selected_stage = "practice"
 var transition = root.get_node("SceneTransition")
 transition.change_scene("res://scenes/main_menu.tscn")
 await transition.transition_finished
 paused = true
 transition.cover.show()
 transition.material.set_shader_parameter("factor",0.5)
 await shot("ink_transition_midpoint")
 transition.material.set_shader_parameter("factor",1.0)
 var image: Image = await shot("ink_transition_covered")
 var target := Color("cf6195")
 for point in [Vector2i(5,5),Vector2i(640,360),Vector2i(1270,710)]:
  var color := image.get_pixelv(point)
  assert(absf(color.r-target.r) < 0.04 and absf(color.g-target.g)<0.04 and absf(color.b-target.b)<0.04,"Wipe must fully conceal scene")
 transition.cover.hide()
 transition.material.set_shader_parameter("factor",0.0)
 paused = false
 transition.change_scene("res://scenes/game_placeholder.tscn")
 await transition.transition_finished
 var game = current_scene
 game.auto_pause_on_focus_loss = false
 var menu = game.get_node("Interface/PauseOverlay")
 menu.toggle_pause()
 assert(paused and menu.visible)
 menu.refresh_opacity()
 await shot("ui_pause_visible")
 menu.show_stats()
 menu.refresh_opacity()
 await shot("ui_stats_visible")
 # Use the real pause exit handler, including its save rules.
 menu.return_to_menu()
 await transition.transition_finished
 assert(not paused and current_scene.scene_file_path.ends_with("main_menu.tscn"))
 print("PASS: supplied shader midpoint and opaque endpoint; actual paused menu return")
 print("FINAL UI CHECKS PASSED")
 quit()
