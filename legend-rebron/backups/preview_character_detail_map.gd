extends SceneTree
func _initialize(): call_deferred("preview")
func preview():
 var data = root.get_node("GameData")
 for stage in data.STAGES:
  data.selected_stage = stage
  var detail = load("res://scenes/character_detail.tscn").instantiate()
  root.add_child(detail)
  var background = detail.get_node("SelectedStageBackground")
  assert(background.selected == data.STAGES.find(stage) and not background.auto_cycle)
  await create_timer(0.2).timeout
  if stage == "desert":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/character_detail_map_preview.png")
  detail.queue_free()
  await process_frame
 print("PASS: Character Detail background follows all three selected stages")
 quit()
