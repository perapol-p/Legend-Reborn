extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(12.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_low_health.save"
 data.progress_path = "user://test_low_health_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var run = game.get_node("RunState")
 var feedback = game.damage_feedback
 run.set_physics_process(false)
 var previous := -1.0
 for hp in [100.0,75.0,50.0,25.0,5.0]:
  run.damage_taken = 100.0-hp
  run.changed.emit()
  feedback._process(0.5)
  assert(feedback.low_health_target > previous)
  previous = feedback.low_health_target
  if hp == 100.0: assert(not feedback.visible)
  else: assert(feedback.visible)
 await process_frame
 await process_frame
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/low_health_preview.png")
 feedback._on_damage_received(10.0,Vector3(0,0,20))
 assert(not feedback.hits.is_empty())
 feedback._process(1.0)
 assert(feedback.hits.is_empty() and feedback.visible)
 assert(float(feedback.vignette_material.get_shader_parameter("low_health")) > 0.8)
 run.heal_fraction(1.0)
 feedback._process(1.0)
 assert(feedback.low_health_target == 0.0 and not feedback.visible)
 # Maximum-HP item upgrades affect the warning by percentage, not fixed missing HP.
 run.damage_taken = 50.0
 run.changed.emit()
 var strength: float = feedback.low_health_target
 run.owned_ids.append("furry_set")
 run.item_counts["furry_set"] = 1
 run.changed.emit()
 assert(feedback.low_health_target < strength)
 paused = true
 feedback._process(1.0)
 assert(not feedback.visible)
 paused = false
 run.finished = true
 feedback._process(1.0)
 assert(not feedback.visible)
 print("PASS: lower HP gives progressively stronger red border; persistent after hit fade; healing removes red; Max HP uses ratio; direction markers retained; pause/end hidden")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
