extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_credits_run.save"
 data.progress_path = "user://test_credits_progress.cfg"
 var home = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(home)
 current_scene = home
 assert(home.get_node_or_null("Center/Menu/Subtitle")==null)
 await create_timer(0.2).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/home_without_description.png")
 home.queue_free()
 await process_frame
 var credits = load("res://scenes/credits.tscn").instantiate()
 root.add_child(credits)
 current_scene = credits
 await process_frame
 var text := ""
 for label in credits.find_children("*","Label",true,false): text += label.text+"\n"
 for member in credits.TEAM:
  assert(text.contains(member["name"]) and text.contains(member["id"]) and text.contains(member["role"]))
 assert(not text.contains("Your Team"))
 assert(credits.get_node("Center/Panel/VBox/Back").get_global_rect().end.y<720)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/team_credits_preview.png")
 print("PASS: Home description removed, all three exact names/IDs/roles displayed, Credits layout fits 720p")
 quit()
