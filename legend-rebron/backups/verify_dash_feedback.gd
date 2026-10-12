extends SceneTree
func _initialize():
 call_deferred("verify")
func step(player, delta := 1.0/60.0):
 await physics_frame
 player._physics_process(delta)
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_dash_feedback.save"
 data.progress_path = "user://test_dash_feedback_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 await physics_frame
 var player = game.get_node("Player")
 player.set_physics_process(false)
 player.position = Vector3(0,0.05,0)
 player.velocity = Vector3.ZERO
 var starts := [0]
 var ready := [0]
 player.dash_started.connect(func(): starts[0] += 1)
 player.dash_ready.connect(func(): ready[0] += 1)
 player.dash_remaining = 0.0
 player.dash_recovery = 0.0
 player.request_dash(Vector3.ZERO)
 await step(player)
 assert(starts[0] == 1)
 assert(player.dash_direction.is_equal_approx(Vector3.FORWARD))
 var first_speed = Vector2(player.velocity.x,player.velocity.z).length()
 var initial_direction = player.dash_direction
 player.rotation.y = PI/2.0
 await step(player)
 assert(player.dash_direction.is_equal_approx(initial_direction))
 var position_at_start = player.position.z
 for i in 7: await step(player)
 var last_speed = Vector2(player.velocity.x,player.velocity.z).length()
 assert(first_speed > last_speed and first_speed > player.dash_speed)
 assert(player.camera.fov == 90.0)
 assert(absf(player.head.rotation.z) <= deg_to_rad(0.6) + 0.0001)
 player.dash_remaining = 0.0
 player.dash_recovery = 0.10
 player.request_dash(Vector3.RIGHT)
 for i in 7: await step(player)
 assert(starts[0] == 2 and player.dash_direction == Vector3.RIGHT)
 # Pressing too early expires, rather than firing an unexpected delayed dash.
 player.dash_remaining = 0.0
 player.dash_recovery = 0.25
 player.request_dash(Vector3.LEFT)
 for i in 17: await step(player)
 assert(starts[0] == 2 and ready[0] == 1)
 player.request_dash(Vector3.LEFT)
 paused = true
 assert(player.dash_buffer == 0.0)
 await process_frame
 await process_frame
 assert(not game.dash_feedback.visible)
 paused = false
 player.input_enabled = false
 player.request_dash(Vector3.RIGHT)
 assert(player.dash_buffer == 0.0)
 player.input_enabled = true
 player.dash_recovery = 0.0
 player.request_dash(Vector3.LEFT)
 await step(player)
 # New and old single-slot saves both restore dash phase safely.
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 var remaining = player.dash_remaining
 var duration = player.dash_total_duration
 codec.restore_world(game,saved)
 assert(is_equal_approx(player.dash_remaining, remaining))
 assert(is_equal_approx(player.dash_total_duration, duration))
 saved["player"].erase("dash_total_duration")
 codec.restore_world(game,saved)
 assert(is_equal_approx(player.dash_total_duration,player.current_dash_duration()))
 # Katana's existing longer dash stays intact.
 game.get_node("RunState").equipped_weapon_id = "katana"
 game.get_node("RunState").weapon_levels["katana"] = 3
 player.dash_remaining = 0.0
 player.dash_recovery = 0.0
 player.request_dash(Vector3.RIGHT)
 await step(player)
 assert(is_equal_approx(player.dash_total_duration,player.dash_duration*1.5))
 await process_frame
 await process_frame
 assert(game.dash_feedback.wind > 0.0)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/dash_feedback_preview.png")
 print("PASS: eased dash speed, locked/fallback direction, 150ms buffer, early input expiry, ready cue, pause/input guards, steady FOV, old/new saves, katana duration, wind UI")
 game.queue_free()
 await process_frame
 await process_frame
 quit()