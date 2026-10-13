extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_dps.save"
 data.progress_path = "user://test_dps_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var run = game.get_node("RunState")
 var hud = game.get_node("Interface/HUD")
 var player = game.get_node("Player")
 var combat = player.get_node("Head/Camera3D/Combat")
 hud.set_process(false)
 player.set_physics_process(false)
 combat.set_physics_process(false)
 run.set_physics_process(false)
 assert(hud.dps_value == 0.0 and not hud.dps_area.visible)
 var target = load("res://scenes/monster.tscn").instantiate()
 target.max_health = 20.0
 game.add_child(target)
 combat.deal_hit(target,0.0)
 assert(hud.dps_value == 0.0 and not hud.dps_area.visible)
 combat.deal_hit(target,12.0,"sword")
 assert(hud.dps_value == 12.0)
 hud.update_dps(0.4)
 combat.deal_hit(target,100.0,"bow",false,true)
 assert(hud.dps_value == 20.0,"Overkill must only add remaining 8 HP")
 combat.deal_hit(target,100.0)
 assert(hud.dps_value == 20.0,"Dead enemy must not add damage")
 hud.update_dps(0.61)
 assert(hud.dps_value == 8.0,"Only the second hit remains in the last second")
 var clock: float = hud.dps_clock
 paused = true
 hud.update_dps(10.0)
 assert(hud.dps_clock == clock and hud.dps_value == 8.0)
 paused = false
 hud.update_dps(0.40)
 assert(is_zero_approx(hud.dps_value))
 assert(run.peak_dps == 20.0)
 # Area damage to separate targets contributes to the same meter.
 for point in [Vector3(5,0,-8),Vector3(6,0,-8)]:
  var enemy = load("res://scenes/monster.tscn").instantiate()
  enemy.max_health = 10.0
  enemy.position = point
  game.add_child(enemy)
 await physics_frame
 await physics_frame
 combat.explode(Vector3(5.5,1,-8),2.0,6.0,null,false,"spellbook")
 assert(is_equal_approx(hud.dps_value,12.0))
 assert(hud.dps_peak == 20.0)
 hud.update_dps(1.01)
 assert(is_zero_approx(hud.dps_value))
 # Persist the highest DPS, but begin Continue with an empty 1s window.
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 saved["stage"] = "grassland"
 assert(data.save_active_run(saved) == OK)
 var loaded: Dictionary = data.load_active_run()
 game.queue_free()
 await process_frame
 await process_frame
 data.selected_stage = "grassland"
 data.pending_resume = loaded
 game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 hud = game.get_node("Interface/HUD")
 run = game.get_node("RunState")
 combat = game.get_node("Player/Head/Camera3D/Combat")
 assert(hud.dps_peak == 20.0 and hud.dps_value == 0.0)
 var enemy = load("res://scenes/monster.tscn").instantiate()
 enemy.max_health = 1000.0
 game.add_child(enemy)
 combat.deal_hit(enemy,250.0,"sword")
 await create_timer(0.12).timeout
 assert(hud.dps_label.text == "250" and hud.dps_area.visible)
 assert(hud.dps_area.find_children("*","ProgressBar",true,false).is_empty())
 assert(hud.dps_area.global_position.y == 16.0)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/dps_meter_preview.png")
 print("PASS: actual HP loss, overkill/dead/miss excluded; rolling 1s expiration; area damage sums; pause freezes; peak saved on Continue; empty resumed window; number-only counter at top right, hidden when idle")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
