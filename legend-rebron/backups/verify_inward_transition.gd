extends SceneTree
func _initialize(): call_deferred("verify")
func frame(name: String) -> Image:
 await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 image.save_png("res://backups/"+name+".png")
 return image
func verify():
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_inward_transition.save"
 data.progress_path = "user://test_inward_transition_progress.cfg"
 var transition = root.get_node("SceneTransition")
 transition.change_scene("res://scenes/main_menu.tscn")
 await transition.transition_finished
 paused = true
 transition.cover.show()
 transition.material.set_shader_parameter("factor",0.0)
 var clear: Image = await frame("inward_transition_clear")
 transition.material.set_shader_parameter("factor",0.5)
 var middle: Image = await frame("inward_transition_middle")
 assert(middle.get_pixel(5,5).r < 0.01)
 assert(middle.get_pixel(1270,710).r < 0.01)
 assert(middle.get_pixel(640,360).is_equal_approx(clear.get_pixel(640,360)),"Centre must remain visible during inward wipe")
 transition.material.set_shader_parameter("factor",1.0)
 var closed: Image = await frame("inward_transition_closed")
 for point in [Vector2i(5,5),Vector2i(640,360),Vector2i(1270,710)]:
  var color := closed.get_pixelv(point)
  assert(color.r < 0.01 and color.g < 0.01 and color.b < 0.01)
 transition.cover.hide()
 transition.material.set_shader_parameter("factor",0.0)
 paused = false
 transition.change_scene("res://scenes/stage_select.tscn")
 transition.change_scene("res://scenes/credits.tscn")
 await transition.transition_finished
 assert(current_scene.scene_file_path.ends_with("stage_select.tscn"))
 assert(not paused and not transition.cover.visible)
 print("PASS: black ink closes from edges to centre, fully covers screen, duplicate-click guard, scene swap")
 quit()
