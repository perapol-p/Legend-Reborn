extends SceneTree
func _initialize(): call_deferred("verify")
func clear_spells():
 for node in get_nodes_in_group("weapon_projectiles"): node.queue_free()
 for node in get_nodes_in_group("weapon_tornadoes"): node.queue_free()
 await process_frame
func verify():
 create_timer(25.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_staff_chance.save"
 data.progress_path = "user://test_staff_chance_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var run = game.get_node("RunState")
 var combat = game.get_node("Player/Head/Camera3D/Combat")
 game.get_node("Player").set_physics_process(false)
 combat.equip("staff")
 combat.set_physics_process(false)
 run.catalog.data["base_stats"]["crit_chance"] = 0.0
 var held_rates: Array = []
 for level in [1,2,3,4,5]:
  run.weapon_levels["spellbook"] = level
  run.rng.seed = 101+level
  var samples := 40 if level < 5 else 20
  var tornado_start: int = combat.tornadoes_created
  for i in samples:
   var before: int = combat.projectiles_fired
   combat.resolve_attack()
   assert(combat.projectiles_fired == before+1,"Every staff cast must fire exactly one ball")
   var shots = get_nodes_in_group("weapon_projectiles").filter(func(node): return not node.is_queued_for_deletion())
   assert(shots.size() == 1 and shots[0].kind == "magic_wave")
   assert(shots[0].magic_vfx != null)
   await clear_spells()
  var tornado_count: int = combat.tornadoes_created-tornado_start
  if level < 3: assert(tornado_count == 0)
  elif level < 5: assert(tornado_count > 0 and tornado_count < samples)
  else: assert(tornado_count == samples)
  print("LV ",level,": ",samples," single fireballs, ",tornado_count," tornado procs; cooldown ",combat.attack_cooldown())
  if level >= 3:
   assert(is_equal_approx(combat.staff_tornado_chance(),[0.25,0.5,1.0][level-3]))
   combat.cooldown = 0.0
   combat.pending = -1.0
   combat.attack_held = true
   var serial: int = combat.attack_serial
   for i in 40:
    combat._physics_process(0.05)
    await clear_spells()
   held_rates.append(combat.attack_serial-serial)
   combat.attack_held = false
   serial = combat.attack_serial
   for i in 16:
    combat._physics_process(0.05)
    await clear_spells()
   assert(combat.attack_serial == serial,"Releasing hold must stop repeated casts")
   assert(combat.view.animation_player.speed_scale >= 1.0)
 assert(held_rates[0] < held_rates[1] and held_rates[1] < held_rates[2])
 run.weapon_levels["spellbook"] = 4
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 combat.equip("sword")
 codec.restore_run(game,saved)
 codec.restore_world(game,saved)
 assert(combat.weapon_id == "spellbook" and combat.weapon_level() == 4)
 assert(combat.staff_tornado_chance() == 0.5 and combat.attack_cooldown() == 0.5)
 assert(run.weapon_ability().contains("50%"))
 print("PASS: one ball at every level; LV3/4/5 tornado chances 25/50/100 percent; hold rates increase ",held_rates,"; release stops; casting animation and old save ID preserved")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
