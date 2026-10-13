extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(40,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_staff_explosion.save"
 data.progress_path = "user://test_staff_explosion_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.auto_pause_on_focus_loss = false
 var player = game.get_node("Player")
 player.set_physics_process(false)
 player.position = Vector3.ZERO
 player.rotation = Vector3.ZERO
 player.head.rotation = Vector3(-0.12,0,0)
 var run = game.get_node("RunState")
 run.set_physics_process(false)
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.equip("spellbook")
 run.weapon_levels["spellbook"] = 4
 assert(not combat.try_explosion())
 run.weapon_levels["spellbook"] = 5
 paused = true
 assert(not combat.try_explosion())
 paused = false
 # Direct E event goes through the combat input handler.
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 var key := InputEventKey.new()
 key.physical_keycode = KEY_E
 key.pressed = true
 game.healing.selected_supply = -1
 combat._unhandled_input(key)
 assert(is_equal_approx(combat.explosion_cooldown,30.0))
 assert(not combat.try_explosion())
 var effect = get_nodes_in_group("staff_explosions")[0]
 assert(effect.materials.size()==9)
 var targets: Array = []
 for offset in [Vector3(2,0,0),Vector3(4,0,0),Vector3(6,0,0),Vector3(12,0,0),Vector3(36,0,0)]:
  var body = load("res://scenes/monster.tscn").instantiate()
  body.max_health = 10000
  body.position = effect.position+offset
  game.add_child(body)
  body.set_physics_process(false)
  targets.append(body)
 await physics_frame
 var elapsed: float = effect.age
 var cooldown: float = combat.explosion_cooldown
 paused = true
 await create_timer(0.15,true).timeout
 assert(effect.age==elapsed and combat.explosion_cooldown==cooldown)
 paused = false
 await create_timer(2.7).timeout
 assert(not effect.damage_applied and targets[0].health == 10000,"Damage must wait for 3-second charge")
 var aim: Vector3 = player.head.rotation
 await create_timer(0.4).timeout
 assert(effect.damage_applied)
 assert(player.shake_remaining > 0.0,"Impact must start camera shake")
 assert(player.head.rotation.is_equal_approx(aim),"Shake must not alter aim or roll")
 for i in 4: assert(targets[i].health < 10000,"All enemies in blast including those behind another enemy must take damage")
 assert(targets[4].health==10000,"Outside radius must not take damage")
 var hp: float = targets[0].health
 await create_timer(0.15).timeout
 assert(targets[0].health==hp,"Explosion damage occurs once")
 # Confirm cooldown and completed impact survive a real world restore.
 var codec = load("res://scripts/run_save_codec.gd")
 var saved: Dictionary = codec.capture(game)
 assert(saved["combat"]["explosion_cooldown"] > 26.0)
 assert(saved["staff_explosions"][0]["damage_applied"])
 effect.queue_free()
 for body in targets: body.queue_free()
 await process_frame
 codec.restore_world(game,saved)
 var restored = get_nodes_in_group("staff_explosions")[0]
 assert(restored.damage_applied and restored.age > 3.0)
 assert(is_equal_approx(combat.explosion_cooldown,saved["combat"]["explosion_cooldown"]))
 restored.age = 3.6
 restored._physics_process(0.0)
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.global_position = restored.global_position+Vector3(45,28,60)
 camera.look_at(restored.global_position+Vector3.UP*20)
 camera.current = true
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/staff_explosion_long_cast_preview.png")
 await create_timer(1.5).timeout
 assert(get_nodes_in_group("staff_explosions").is_empty(),"VFX must clean up")
 assert(player.shake_remaining == 0.0 and player.camera.h_offset == 0.0 and player.camera.v_offset == 0.0,"Shake must settle exactly")
 player.shake_camera()
 paused = true
 assert(player.shake_remaining == 0.0 and player.camera.h_offset == 0.0 and player.camera.v_offset == 0.0,"Pause must clear shake")
 paused = false
 combat.explosion_cooldown = 0.0
 game.healing.selected_supply = 0
 combat._unhandled_input(key)
 assert(get_nodes_in_group("staff_explosions").is_empty(),"Supplies have priority over explosion on E")
 game.healing.selected_supply = -1
 combat.equip("sword")
 assert(not combat.try_explosion())
 combat.equip("spellbook")
 assert(player.shake_remaining == 0.0 and player.camera.h_offset == 0.0 and player.camera.v_offset == 0.0,"Shake must settle exactly")
 player.shake_camera()
 paused = true
 assert(player.shake_remaining == 0.0 and player.camera.h_offset == 0.0 and player.camera.v_offset == 0.0,"Pause must clear shake")
 paused = false
 combat.explosion_cooldown = 0.01
 await physics_frame
 await physics_frame
 assert(combat.try_explosion(),"Skill can be used after cooldown expires")
 run.finished = true
 await physics_frame
 await physics_frame
 assert(get_nodes_in_group("staff_explosions").is_empty())
 print("PASS: 3-second charge, impact shake without aim/roll changes, exact reset, pause clearing; LV5/E gating, 30s cooldown, pause freeze, AOE once, range, unlimited victims, Continue, supply priority, reuse and cleanup")
 quit()
