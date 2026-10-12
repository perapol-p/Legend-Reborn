extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_magic_final.save"
 data.progress_path = "user://test_magic_final_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var player = game.get_node("Player")
 var run = game.get_node("RunState")
 var combat = player.get_node("Head/Camera3D/Combat")
 player.position = Vector3(0,0.05,0)
 player.set_physics_process(false)
 combat.equip("staff")
 combat.set_physics_process(false)
 run.catalog.data["base_stats"]["crit_chance"] = 0.0
 run.weapon_levels["spellbook"] = 5
 await physics_frame
 await physics_frame
 combat.cooldown = 0.0
 assert(combat.try_attack())
 combat._physics_process(0.20)
 var shots = get_nodes_in_group("weapon_projectiles")
 assert(shots.size() == 4)
 var nuke: Node3D
 for shot in shots:
  shot.set_physics_process(false)
  assert(shot.magic_vfx != null)
  if shot.kind == "nuke": nuke = shot
 assert(nuke != null and nuke.splash == 8.0 and nuke.magic_vfx.purple)
 assert(get_nodes_in_group("weapon_tornadoes").size() == 1)
 var origin: Vector3 = player.camera.global_position
 var release: Vector3 = combat.view.cast_position()
 var wall := StaticBody3D.new()
 wall.position = origin.lerp(release,0.5)
 var collision := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(0.15,0.15,0.15)
 collision.shape = box
 wall.add_child(collision)
 game.add_child(wall)
 await physics_frame
 await physics_frame
 var blocked = combat.fire_projectile("magic_wave",Vector3.FORWARD,16.0,22.0,0.15,false,0.0,release)
 assert(blocked.is_queued_for_deletion(),"Wall between camera and staff must block spell")
 var target = load("res://scenes/monster.tscn").instantiate()
 target.max_health = 1000.0
 target.position = Vector3(3,0.05,-4)
 game.add_child(target)
 await physics_frame
 await physics_frame
 var damage: float = nuke.damage
 nuke.impact(wall,Vector3(0,1,-5))
 assert(is_equal_approx(target.health,1000.0-damage),"Nuke splash must retain original damage")
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.position = Vector3(7,5,6)
 camera.look_at(Vector3(0,1,-5))
 combat.view.hide()
 await create_timer(0.2).timeout
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/magic_nuke_preview.png")
 print("PASS: LV5 retains 3 piercing spells + nuke + vortex; arcane nuke visuals; original splash radius/damage; close walls block staff launch")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
