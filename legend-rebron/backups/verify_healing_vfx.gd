extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(15.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_healing_vfx.save"
 data.progress_path = "user://test_healing_vfx_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var player = game.get_node("Player")
 var run = game.get_node("RunState")
 var healing = game.healing
 var effect = game.healing_feedback
 player.set_physics_process(false)
 run.set_physics_process(false)
 healing.set_physics_process(false)
 assert(not effect.visible and effect.effects_started == 0)
 assert(run.heal_fraction(0.2) == 0.0 and effect.effects_started == 0)
 run.damage_taken = 50.0
 healing.spawn_heart(player.global_position)
 assert(healing.collect_heart(healing.hearts[0]) == 8.0)
 assert(effect.effects_started == 1 and effect.icons.size() == 4)
 var chest = healing.supplies[0]["node"]
 player.global_position = chest.global_position+Vector3(0,0.1,2.2)
 player.camera.look_at(chest.global_position+Vector3.UP*0.5)
 await physics_frame
 await physics_frame
 assert(healing.open_supply(0) == 20.0)
 assert(effect.effects_started == 2)
 await create_timer(0.2).timeout
 assert(float(effect.border_material.get_shader_parameter("strength")) > 0.0)
 assert(effect.visible)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/healing_vfx_preview.png")
 await create_timer(1.4).timeout
 assert(effect.icons.is_empty() and not effect.visible)
 effect.passive_cooldown = 0.0
 var starts: int = effect.effects_started
 run.regen_elapsed = 0.0
 run._physics_process(1.0)
 assert(effect.effects_started == starts+1 and effect.flash_strength < 0.1)
 run._physics_process(1.0)
 assert(effect.effects_started == starts+1,"Passive regen must not spam effects every second")
 # Damage warning reduces the healing border so it stays readable.
 run.heal_fraction(0.01)
 player.damage_received.emit(1.0,Vector3.ZERO)
 assert(effect.flash_time <= 0.08)
 for i in 10:
  effect._process(0.15)
  run.heal_fraction(0.001)
 assert(effect.icons.size() <= 12)
 paused = true
 await process_frame
 await process_frame
 assert(not effect.visible and effect.icons.is_empty())
 assert(effect.border_material.get_shader_parameter("strength") == 0.0)
 var count: int = effect.effects_started
 run.heal_fraction(0.1)
 assert(effect.effects_started == count)
 paused = false
 run.finished = true
 run.heal_fraction(0.1)
 assert(effect.effects_started == count)
 print("PASS: real heart/supply heals trigger green edge and floating medical crosses; full HP silent; effects fade; passive regen subtle/throttled; particle limit; damage priority; pause/death guards")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
