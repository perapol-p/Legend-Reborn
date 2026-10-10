extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_staff.save"
 data.progress_path = "user://test_staff_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var combat = game.get_node("Player/Head/Camera3D/Combat")
 var run = game.get_node("RunState")
 game.command_console.submit("/weapon staff")
 assert(combat.weapon_id == "spellbook" and run.weapon_name() == "Staff")
 assert(combat.view.name == "Staff")
 assert(combat.view.animation_player.current_animation == "Idle")
 assert(combat.view.get_node("Model/Arm_Rig_Export/Skeleton3D/Arm_Export") != null)
 assert(game.practice_ui.buttons.has("/weapon staff"))
 await create_timer(0.2).timeout
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/staff_idle_preview.png")
 var before: int = combat.projectiles_fired
 combat.cooldown = 0.0
 assert(combat.try_attack())
 assert(combat.view.animation_player.current_animation == "Attack")
 await create_timer(0.23).timeout
 assert(combat.projectiles_fired == before+1)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/staff_attack_preview.png")
 await create_timer(0.9).timeout
 assert(combat.view.animation_player.current_animation == "Idle")
 run.weapon_levels["spellbook"] = 3
 combat.cooldown = 0.0
 var tornados: int = combat.tornadoes_created
 assert(combat.try_attack())
 await create_timer(0.25).timeout
 assert(combat.tornadoes_created == tornados+1)
 run.weapon_levels["spellbook"] = 4
 combat.special_cooldown = 0.0
 assert(combat.try_special(),"Staff must retain warp ability")
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 combat.equip("sword")
 codec.restore_run(game,saved)
 codec.restore_world(game,saved)
 assert(combat.weapon_id == "spellbook" and combat.view.name == "Staff")
 assert(run.weapon_level() == 4)
 game.command_console.submit("/weapon spellbook")
 assert(combat.view.name == "Staff")
 print("PASS: asset staff/arms, original Idle/Attack, staff command/UI name, magic projectile, tornado, warp and legacy spellbook save/command compatibility")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
