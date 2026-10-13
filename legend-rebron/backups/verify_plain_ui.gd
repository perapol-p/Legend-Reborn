extends SceneTree
func _initialize(): call_deferred("verify")
func photo(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/plain_"+name+".png")
func verify():
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_plain_ui.save"
 data.progress_path = "user://test_plain_ui_progress.cfg"
 data.selected_stage = "desert"
 var transition = root.get_node("SceneTransition")
 for name in ["main_menu","stage_select","character_detail"]:
  transition.change_scene("res://scenes/"+name+".tscn")
  await transition.transition_finished
  if name == "main_menu":
   assert(current_scene.get_node("Center/Menu/Title").text == "LEGEND REBORN")
   assert(current_scene.get_node("Center/Menu/Play").text == "PLAY")
  if name == "stage_select":
   for button in current_scene.stage_buttons.values():
    assert(button.get_theme_stylebox("normal") is StyleBoxEmpty)
    assert(not button.get_theme_stylebox("hover").draw_center)
  if name == "character_detail":
   var style = current_scene.get_node("Center/Panel/VBox/Buttons/Go").get_theme_stylebox("normal")
   assert(style.texture.resource_path.ends_with("TextBox2.png"))
  await photo(name)
 data.selected_stage = "practice"
 transition.change_scene("res://scenes/game_placeholder.tscn")
 await transition.transition_finished
 var hud = current_scene.get_node("Interface/HUD")
 assert(hud.find_child("CharacterPortrait",true,false).get_theme_stylebox("panel") is StyleBoxEmpty)
 await photo("hud")
 var menu = current_scene.get_node("Interface/PauseOverlay")
 menu.toggle_pause()
 assert(menu.resume.get_theme_stylebox("normal").texture.resource_path.ends_with("TextBox2.png"))
 await photo("pause")
 print("PASS: original Home layout, transparent stage cards, plain action buttons, frameless HUD")
 quit()
