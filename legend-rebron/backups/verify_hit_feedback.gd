extends SceneTree
func _initialize():
 call_deferred("verify")
func verify():
 create_timer(12.0, true, false, true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_hit_feedback.save"
 data.progress_path = "user://test_hit_feedback_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 await physics_frame
 var combat = game.get_node("Player/Head/Camera3D/Combat")
 var feedback = game.hit_feedback
 var monster = load("res://scenes/monster.tscn").instantiate()
 monster.max_health = 1000
 game.add_child(monster)
 combat.deal_hit(monster,0)
 assert(feedback.confirmations == 0 and feedback.sounds_played == 0)
 combat.deal_hit(monster,1,"sword",false,false)
 assert(feedback.confirmations == 1 and feedback.visible and feedback.priority == 0)
 assert(feedback.sounds_played == 1)
 assert(monster.damage_flash.overlay.get_shader_parameter("strength") == 1.0)
 assert(monster.model.scale == Vector3.ONE)
 combat.deal_hit(monster,1,"bow",false,true)
 assert(feedback.priority == 1 and feedback.sounds_played == 1)
 combat.deal_hit(monster,1,"bow",false,false)
 assert(feedback.priority == 1)
 await create_timer(0.12).timeout
 assert(monster.damage_flash.remaining == 0.0)
 combat.deal_hit(monster,99999,"sword",false,false)
 assert(feedback.priority == 2 and feedback.sounds_played == 2)
 var count = feedback.confirmations
 combat.deal_hit(monster,100,"bow",false,true)
 assert(feedback.confirmations == count)
 paused = true
 await process_frame
 await process_frame
 assert(not feedback.visible and not feedback.impact.playing)
 paused = false
 await create_timer(1.0).timeout
 assert(not is_instance_valid(monster))
 print("PASS: rejected hit silent; valid hit flash/white marker/sound; gold crit; red kill; burst priority/audio limit; pause cleanup; death cleanup")
 game.queue_free()
 await process_frame
 await process_frame
 quit()