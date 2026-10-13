extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_chant_run.save"
 data.progress_path = "user://test_chant_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var combat = game.get_node("Player/Head/Camera3D/Combat")
 combat.set_physics_process(false)
 game.get_node("Player").set_physics_process(false)
 var run = game.get_node("RunState")
 run.weapon_levels["spellbook"] = 5
 assert(combat.try_explosion())
 var effect = get_nodes_in_group("staff_explosions")[0]
 assert(is_equal_approx(effect.cast_duration,effect.CAST_SOUND.get_length()))
 assert(absf(effect.cast_duration-5.46)<0.01)
 assert(effect.chant.playing and effect.chant.bus=="Effects")
 await create_timer(0.2).timeout
 var age: float = effect.age
 var position: float = effect.chant.get_playback_position()
 paused = true
 await create_timer(0.15,true).timeout
 assert(effect.age==age)
 assert(absf(effect.chant.get_playback_position()-position)<0.05,"Pause must freeze chant with the charge")
 paused = false
 # Continue midway through casting resumes the same sound at the saved offset.
 effect.set_physics_process(false)
 effect.age = 2.0
 var codec = load("res://scripts/run_save_codec.gd")
 var saved: Dictionary = codec.capture(game)
 assert(saved["staff_explosions"][0]["cast_duration"]==effect.cast_duration)
 effect.queue_free()
 await process_frame
 codec.restore_world(game,saved)
 effect = get_nodes_in_group("staff_explosions")[0]
 effect.set_physics_process(false)
 assert(effect.chant.playing and effect.age==2.0)
 assert(absf(effect.chant.get_playback_position()-2.0)<0.1)
 effect._physics_process(effect.cast_duration-effect.age-0.02)
 assert(effect.hits_done==0 and game.sfx.played["magic_explosion"]==0)
 effect._physics_process(0.03)
 assert(effect.hits_done==1 and not effect.chant.playing)
 assert(game.sfx.played["magic_explosion"]==1)
 effect._physics_process(1.7)
 assert(effect.hits_done==10 and game.sfx.played["magic_explosion"]==1)
 print("PASS: chant duration ",effect.cast_duration," seconds; charge ends with sound; pause synchronised; Continue resumes at saved audio offset; Explosion follows once and still deals ten hits")
 quit()
