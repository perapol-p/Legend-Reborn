extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_wizard_party.save"
 data.progress_path = "user://test_wizard_party_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 data.graphics_quality = "low"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var player = game.get_node("Player")
 player.set_physics_process(false)
 var run = game.get_node("RunState")
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.set_physics_process(false)
 var sfx = game.sfx
 for id in ["magic_fireball","magic_wind","magic_explosion"]:
  assert(sfx.SOUNDS[id].get_length()>0.0)
  print(id," audio seconds: ",sfx.SOUNDS[id].get_length())
 run.weapon_levels["spellbook"] = 1
 combat.resolve_attack()
 assert(sfx.played["magic_fireball"]==1)
 var tornado = combat.spawn_tornado(Vector3(5,1,-5),1,3.5,2.5)
 var tornado2 = combat.spawn_tornado(Vector3(8,1,-5),1,3.5,2.5)
 sfx._physics_process(0.2)
 assert(sfx.wind_voice.playing and sfx.played["magic_wind"]==1)
 sfx._physics_process(0.2)
 assert(sfx.played["magic_wind"]==1,"Tornado wind must have a single shared loop")
 tornado.queue_free()
 tornado2.queue_free()
 sfx._physics_process(0.2)
 assert(not sfx.wind_voice.playing)
 run.weapon_levels["spellbook"] = 5
 assert(combat.try_explosion())
 var effect = get_nodes_in_group("staff_explosions")[0]
 effect.set_physics_process(false)
 assert(sfx.played["magic_explosion"]==0)
 effect._physics_process(effect.cast_duration+0.1)
 assert(sfx.played["magic_explosion"]==1)
 effect._physics_process(1.7)
 assert(effect.hits_done==10 and sfx.played["magic_explosion"]==1,"One sound for the whole ten-hit blast")
 effect.queue_free()
 for shot in get_nodes_in_group("weapon_projectiles"): shot.queue_free()
 run.test_level_up()
 var reward = game.get_node("Interface/RewardOverlay")
 assert(paused and reward.visible)
 assert(reward.level_title.glow.text=="LEVEL UP!")
 assert(reward.celebration.particles.size()==100)
 var generation: int = reward.celebrated_generation
 await create_timer(0.4,true).timeout
 assert(reward.celebration.elapsed>0.3,"Confetti must animate during paused rewards")
 var clock: float = reward.level_title.clock
 assert(clock>0.3 and reward.level_title.lettering.scale != Vector2.ONE)
 reward.refresh()
 assert(reward.celebrated_generation==generation and reward.celebration.elapsed>0.3,"Refresh must not replay the burst")
 assert(not sfx.wind_voice.playing and not sfx.explosion_voice.playing)
 for button in reward.choice_buttons: assert(button.get_global_rect().end.y<720)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/level_up_party_preview.png")
 reward.choice_buttons[0].pressed.emit()
 assert(run.offers.is_empty() and run.total_items()==1 and not paused)
 assert(reward.celebration.particles.is_empty())
 run.test_level_up()
 assert(reward.celebrated_generation!=generation and reward.celebration.particles.size()==100)
 print("PASS: wizard fireball release sound, one wind loop, timed Explosion sound once; animated glowing title and capped multicolour confetti during paused rewards; selection and replay next level")
 quit()
