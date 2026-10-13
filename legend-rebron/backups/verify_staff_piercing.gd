extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_staff_piercing.save"
 data.progress_path = "user://test_staff_piercing_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.auto_pause_on_focus_loss = false
 var player = game.get_node("Player")
 player.set_physics_process(false)
 player.position = Vector3(50,25,50)
 var run = game.get_node("RunState")
 run.set_physics_process(false)
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.set_physics_process(false)
 var wall := StaticBody3D.new()
 var collision := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(6,6,0.3)
 collision.shape = box
 wall.add_child(collision)
 wall.position = Vector3(50,27,35)
 game.add_child(wall)
 for level in [1,2,3]:
  run.weapon_levels["spellbook"] = level
  var targets: Array = []
  for i in 5:
   var monster = load("res://scenes/monster.tscn").instantiate()
   monster.max_health = 10000
   monster.position = Vector3(50,25,32.0 if i==4 else 47-float(i)*3)
   game.add_child(monster)
   monster.set_physics_process(false)
   targets.append(monster)
  await physics_frame
  var shot = combat.fire_projectile("magic_wave",Vector3.FORWARD,100,22,0.15 if level==1 else 0.9,level<=2,0,Vector3(50,26,50))
  assert(shot.piercing == (level <= 2))
  assert(shot.damage_falloff == (0.75 if level<=2 else 1.0))
  await create_timer(0.85).timeout
  if level <= 2:
   for i in 4:
    var expected := 100.0*pow(0.75,i)
    assert(is_equal_approx(10000.0-targets[i].health,expected),"Falloff and ordered real collisions at LV "+str(level))
   assert(targets[4].health==10000,"Terrain must stop piercing fireball")
  else:
   assert(is_equal_approx(10000.0-targets[0].health,100.0))
   assert(targets[1].health==10000,"LV3 behaviour must remain unchanged")
  for body in targets: body.queue_free()
  await process_frame
 # Reduced damage and falloff must both survive a Continue save.
 run.weapon_levels["spellbook"] = 2
 var target = load("res://scenes/monster.tscn").instantiate()
 target.max_health = 10000
 target.position = Vector3(50,25,47)
 game.add_child(target)
 target.set_physics_process(false)
 game.get_node("MonsterSpawner").monsters.append(target)
 var shot = combat.fire_projectile("magic_wave",Vector3.FORWARD,100,22,0.9,true,0,Vector3(50,26,50))
 shot.set_physics_process(false)
 assert(not shot.impact(target,target.aim_point()))
 assert(shot.damage == 75.0)
 # Duplicate contacts must not deal damage or reduce damage again.
 shot.impact(target,target.aim_point())
 assert(shot.damage==75.0 and target.health==9900.0)
 var codec = load("res://scripts/run_save_codec.gd")
 var saved: Dictionary = codec.capture(game)
 assert(saved["shots"][0]["damage"]==75.0 and saved["shots"][0]["damage_falloff"]==0.75)
 target.queue_free()
 shot.queue_free()
 await process_frame
 codec.restore_world(game,saved)
 var restored = get_nodes_in_group("weapon_projectiles")[0]
 restored.set_physics_process(false)
 assert(restored.damage==75.0 and restored.damage_falloff==0.75 and restored.struck.size()==1)
 print("PASS: LV1 and LV2 real piercing collisions with 100/75/56.25/42.1875 damage; walls block; LV3 preserved; no duplicate hit; Continue preserves falloff")
 quit()
