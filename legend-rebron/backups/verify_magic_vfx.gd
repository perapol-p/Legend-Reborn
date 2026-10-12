extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_magic_vfx.save"
 data.progress_path = "user://test_magic_vfx_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var run = game.get_node("RunState")
 var player = game.get_node("Player")
 var combat = player.get_node("Head/Camera3D/Combat")
 player.set_physics_process(false)
 player.position = Vector3(0,0.05,0)
 combat.equip("staff")
 combat.set_physics_process(false)
 run.catalog.data["base_stats"]["crit_chance"] = 0.0
 var target = load("res://scenes/monster.tscn").instantiate()
 target.max_health = 10000.0
 target.position = Vector3(0,0.05,-7)
 game.add_child(target)
 await physics_frame
 await physics_frame
 var cast: Vector3 = combat.view.cast_position()
 assert(cast.distance_to(player.camera.global_position) < 1.5)
 var original_damage: float = float(run.stats()["attack"])*1.6
 var health_before: float = target.health
 run.weapon_levels["spellbook"] = 1
 combat.cooldown = 0.0
 assert(combat.try_attack())
 combat._physics_process(0.20)
 await create_timer(0.55).timeout
 assert(is_equal_approx(target.health,health_before-original_damage),"Magic projectile must retain damage and hit crosshair target")
 assert(not get_nodes_in_group("magic_bursts").is_empty())
 # Restore an active orb and vortex from the existing save codec.
 var shot = combat.fire_projectile("magic_wave",Vector3.FORWARD,16.0,5.0,0.15,false,0.0,Vector3(-4,2,-4))
 shot.set_physics_process(false)
 assert(shot.magic_vfx.trail.emitting)
 var tornado = combat.spawn_tornado(Vector3(4,1.5,-7),7.2,3.5,2.5)
 tornado.set_physics_process(false)
 assert(tornado.model.materials.size() == 3)
 assert(is_equal_approx(tornado.model.rune.global_position.y,0.03))
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.position = Vector3(10,5,3)
 camera.look_at(Vector3(2,1,-7))
 combat.view.hide()
 await create_timer(0.25).timeout
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/magic_vortex_preview.png")
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 codec.restore_world(game,saved)
 var restored_orbs = get_nodes_in_group("weapon_projectiles").filter(func(node): return node.kind == "magic_wave")
 assert(restored_orbs.size() >= 1)
 assert(restored_orbs[-1].magic_vfx != null)
 var restored_vortices = get_nodes_in_group("weapon_tornadoes")
 assert(restored_vortices[-1].model.materials.size() == 3)
 for node in get_nodes_in_group("weapon_projectiles"): node.queue_free()
 for node in get_nodes_in_group("weapon_tornadoes"): node.queue_free()
 await process_frame
 await process_frame
 # Burst visuals never change explosion damage and cannot accumulate without bound.
 var before: float = target.health
 combat.explode(target.global_position+Vector3.UP,8.0,20.0,null,false,"spellbook")
 assert(is_equal_approx(target.health,before-20.0))
 var helper = load("res://scripts/magic_vfx.gd")
 for i in 25: helper.burst(game,Vector3(5,1,-7),0.3,false)
 var live = get_nodes_in_group("magic_bursts").filter(func(node): return not node.is_queued_for_deletion())
 assert(live.size() <= 18)
 var phase: float = live[-1].elapsed
 paused = true
 await process_frame
 await process_frame
 assert(live[-1].elapsed == phase)
 paused = false
 await create_timer(1.1).timeout
 assert(get_nodes_in_group("magic_bursts").is_empty())
 print("PASS: textured staff cast, launch from gem hits aimed target, unchanged damage; orbiting orb/trail; rune/spiral vortex; restored visuals; explosion damage; burst limit/cleanup; pause freezes VFX")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
