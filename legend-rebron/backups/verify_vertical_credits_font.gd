extends SceneTree
func _initialize(): call_deferred("verify")
func photo(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/font_"+name+".png")
func verify():
 create_timer(20,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_font_run.save"
 data.progress_path = "user://test_font_progress.cfg"
 data.selected_stage = "practice"
 var font = load("res://assets/ui/fonts/Font.ttf")
 print("FONT FAMILY: ",font.get_font_name())
 assert(load("res://assets/ui/legend_theme.tres").default_font==font)
 for name in ["main_menu","credits","stage_select","character_select","character_detail"]:
  var screen = load("res://scenes/"+name+".tscn").instantiate()
  root.add_child(screen)
  current_scene = screen
  await photo(name)
  if name=="credits":
   var team = screen.get_node("Center/Panel/VBox/Team")
   assert(team is VBoxContainer and team.get_child_count()==3)
   var last := -1.0
   for entry in team.get_children():
    assert(entry is VBoxContainer)
    assert(entry.global_position.y > last)
    last=entry.global_position.y
    for label in entry.get_children(): assert(label.get_theme_font("font")==font)
   assert(screen.get_node("Center/Panel").get_theme_stylebox("panel") is StyleBoxEmpty)
  screen.queue_free()
  await process_frame
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 game.get_node("RunState").test_level_up()
 await photo("reward")
 var reward = game.get_node("Interface/RewardOverlay")
 for button in reward.choice_buttons: assert(button.get_global_rect().end.y < 720)
 assert(reward.heading.get_theme_font("font")==font)
 var enemy = load("res://scenes/monster.tscn").instantiate()
 game.add_child(enemy)
 assert(enemy.health_label.font==font)
 print("PASS: vertical frameless credits; supplied font in menus, rich text, rewards, HUD and enemy labels")
 game.queue_free()
 await process_frame
 quit()
