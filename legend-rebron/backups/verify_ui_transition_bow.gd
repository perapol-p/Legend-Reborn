extends SceneTree
func _initialize(): call_deferred("verify")
func screenshot(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/"+name+".png")
func verify():
 create_timer(65,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_ui_transition_run.save"
 data.progress_path = "user://test_ui_transition_progress.cfg"
 data.selected_stage = "practice"
 var transition = root.get_node("SceneTransition")
 # Native scene buttons and custom frames both use the supplied texture.
 var theme = load("res://assets/ui/legend_theme.tres")
 for kind in ["Button","OptionButton","CheckButton","CheckBox","MenuButton"]:
  for state in ["normal","hover","pressed","disabled","focus"]:
   assert(theme.get_stylebox(state,kind) is StyleBoxTexture)
 for path in ["main_menu","stage_select","character_select","character_detail","settings","credits"]:
  transition.change_scene("res://scenes/"+path+".tscn")
  # Repeated navigation during the wipe must be ignored.
  transition.change_scene("res://scenes/credits.tscn")
  await transition.transition_finished
  assert(current_scene.scene_file_path == "res://scenes/"+path+".tscn")
  assert(not paused and not transition.busy and not transition.cover.visible)
  await screenshot("ui_"+path)
 print("PASS: texture theme, all menu routes, duplicate-click guard, unpause")
 for character in data.CHARACTERS:
  data.selected_character = character
  transition.change_scene("res://scenes/game_placeholder.tscn")
  await transition.transition_finished
  var game = current_scene
  game.auto_pause_on_focus_loss = false
  game.get_node("MonsterSpawner").enabled = false
  var portrait = game.get_node("Interface/HUD").find_child("CharacterPortrait",true,false)
  assert(portrait.size.x >= 104 and portrait.size.y >= 104)
  var image = portrait.get_node("CharacterImage")
  assert(image.texture == data.character_icon(character))
  assert(image.size.x >= 95 and image.size.y >= 95)
  await screenshot("hud_"+character.replace(" ","_"))
 print("PASS: all character HUD portraits have 96px image area")
 var game = current_scene
 var run = game.get_node("RunState")
 run.set_physics_process(false)
 var player = game.get_node("Player")
 player.set_physics_process(false)
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.equip("bow")
 var targets: Array = []
 for i in 9:
  var monster = load("res://scenes/monster.tscn").instantiate()
  monster.max_health = 10000
  monster.position = Vector3(0,30, -float(i)*2)
  game.add_child(monster)
  monster.set_physics_process(false)
  targets.append(monster)
 for level in range(1,6):
  run.weapon_levels["bow"] = level
  var shot = combat.fire_projectile("bow",Vector3.FORWARD,10,38,0.04,true,0,Vector3(0,32,5))
  shot.set_physics_process(false)
  assert(shot.pierces_remaining == (-1 if level==5 else level))
  var expected := 9 if level==5 else level+1
  var count := 0
  for monster in targets:
   var health: float = monster.health
   var stopped: bool = shot.impact(monster,monster.aim_point())
   assert(monster.health < health)
   count += 1
   if stopped: break
  assert(count == expected,"Piercing target count at level "+str(level))
  if level==5:
   assert(not shot.is_queued_for_deletion())
   assert(shot.impact(game.get_node("Arena/Floor"),Vector3.ZERO),"Wall/floor must stop unlimited arrow")
  shot.queue_free()
  await process_frame
 print("PASS: bow LV1-4 hits 2/3/4/5 targets; LV5 pierces all; terrain stops arrows")
 run.weapon_levels["bow"] = 4
 var shot = combat.fire_projectile("bow",Vector3.FORWARD,10,38,0.04,true,0,Vector3(0,32,5))
 shot.set_physics_process(false)
 shot.impact(targets[0],targets[0].aim_point())
 shot.impact(targets[1],targets[1].aim_point())
 assert(shot.pierces_remaining == 2)
 var codec = load("res://scripts/run_save_codec.gd")
 var saved: Dictionary = codec.capture(game)
 assert(saved["shots"][0]["pierces_remaining"] == 2)
 for actor in targets: actor.queue_free()
 shot.queue_free()
 await process_frame
 codec.restore_world(game,saved)
 var restored = get_nodes_in_group("weapon_projectiles")[0]
 assert(restored.pierces_remaining == 2)
 print("PASS: Continue restores consumed piercing budget")
 var pause_menu = game.get_node("Interface/PauseOverlay")
 pause_menu.show_menu()
 pause_menu.refresh_opacity()
 await screenshot("ui_pause")
 # Transition must finish even when initiated from the paused game.
 transition.change_scene("res://scenes/main_menu.tscn")
 await transition.transition_finished
 assert(not paused and not transition.cover.visible)
 print("PASS: pause panels and return transition")
 print("ALL BOW, HUD, UI THEME AND TRANSITION CHECKS PASSED")
 quit()
