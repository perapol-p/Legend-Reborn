extends SceneTree
func _initialize(): call_deferred("verify")
func photo(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/polished_"+name+".png")
func verify():
 create_timer(55,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_ui_polish.save"
 data.progress_path = "user://test_ui_polish_progress.cfg"
 data.selected_stage = "desert"
 var transition = root.get_node("SceneTransition")
 for name in ["main_menu","stage_select","character_select","character_detail","settings","credits"]:
  transition.change_scene("res://scenes/"+name+".tscn")
  await transition.transition_finished
  await photo(name)
  assert(not paused and not transition.cover.visible)
  if name == "stage_select":
   var scene = current_scene
   scene.stage_buttons["grassland"].mouse_entered.emit()
   assert(scene.background.selected == 0)
   assert(data.selected_stage == "desert")
  if name == "character_select":
   assert(current_scene.character_buttons.size()==3)
   for button in current_scene.character_buttons.values():
    assert(button.get_global_rect().end.y < 720 and button.get_global_rect().end.x < 1280)
  if name == "character_detail":
   var detail = current_scene.get_node("Center/Panel/VBox/Body/Detail")
   assert(detail.bbcode_enabled and not detail.scroll_active)
   assert(detail.get_content_height() < detail.size.y,"Loadout text must fit")
  if name == "settings":
   var panel = current_scene.find_children("*","VBoxContainer",true,false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("settings_panel.gd"))[0]
   for page in ["Keyboard","Crosshair"]:
    panel.show_page(page)
    await photo("settings_"+page.to_lower())
 print("PASS: all menu layouts, stage hover, character portraits, settings pages")
 data.selected_stage = "practice"
 transition.change_scene("res://scenes/game_placeholder.tscn")
 await transition.transition_finished
 var game = current_scene
 game.auto_pause_on_focus_loss = false
 await photo("hud")
 var menu = game.get_node("Interface/PauseOverlay")
 menu.toggle_pause()
 await photo("pause")
 menu.toggle_pause()
 var run = game.get_node("RunState")
 run.test_level_up()
 await photo("reward")
 var reward = game.get_node("Interface/RewardOverlay")
 assert(reward.choice_buttons.size()==3)
 for button in reward.choice_buttons:
  assert(button.get_global_rect().end.y < 720)
 reward.choice_buttons[0].pressed.emit()
 assert(run.offers.is_empty() and run.total_items()==1)
 menu.toggle_pause()
 menu.show_stats()
 menu.refresh_opacity()
 await photo("inventory_stats")
 menu.return_to_menu()
 await transition.transition_finished
 print("PASS: HUD, Pause, item selection, inventory and return transition")
 print("UI POLISH CHECKS PASSED")
 quit()
