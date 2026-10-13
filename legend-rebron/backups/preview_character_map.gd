extends SceneTree
func _initialize(): call_deferred("preview")
func preview():
 var data = root.get_node("GameData")
 data.selected_stage = "desert"
 var screen = load("res://scenes/character_select.tscn").instantiate()
 root.add_child(screen)
 await create_timer(1.0).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/character_selected_map_preview.png")
 screen.queue_free()
 await process_frame
 quit()
