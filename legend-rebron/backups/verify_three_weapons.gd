extends SceneTree
func _initialize():
 call_deferred("verify")
func mouse(combat, pressed: bool):
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = pressed
 combat._unhandled_input(event)
func ticks(combat, seconds: float):
 for i in ceili(seconds / 0.025): combat._physics_process(0.025)
func verify():
 create_timer(12.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_three_weapons.save"
 data.progress_path = "user://test_three_weapons_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 await physics_frame
 var run = game.get_node("RunState")
 var combat = game.get_node("Player/Head/Camera3D/Combat")
 combat.set_physics_process(false)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 assert(combat.ORDER == ["sword","bow","spellbook"])
 assert(not combat.WEAPONS.has("gun") and not combat.WEAPONS.has("katana"))
 assert(not game.practice_ui.buttons.has("/weapon gun") and not game.practice_ui.buttons.has("/weapon katana"))
 assert(not game.command_console.HELP.contains("katana|gun"))
 for id in combat.ORDER:
  combat.equip(id)
  combat.cooldown = 0.0
  combat.bow_ammo = combat.bow_capacity()
  combat.bow_reload = 0.0
  run.weapon_levels[id] = 1
  var serial = combat.attack_serial
  mouse(combat,true)
  ticks(combat,1.8)
  assert(combat.attack_serial >= serial + 2, id + " must repeat from LV1")
  mouse(combat,false)
  serial = combat.attack_serial
  ticks(combat,1.0)
  assert(combat.attack_serial == serial, id + " must stop after release")
  combat.equip("gun")
  combat.equip("katana")
  assert(combat.weapon_id == id)
 combat.equip("bow")
 combat.cooldown = 0.0
 combat.bow_reload = 0.0
 combat.bow_ammo = 1
 mouse(combat,true)
 ticks(combat,0.3)
 assert(combat.bow_reload > 0.0 and combat.bow_ammo == 0)
 var serial = combat.attack_serial
 ticks(combat,1.8)
 assert(combat.attack_serial > serial and combat.bow_ammo > 0)
 paused = true
 assert(not combat.attack_held)
 paused = false
 ticks(combat,1.0)
 mouse(combat,false)
 # Old saves migrate equipment, keep levels/items/time, discard removed perks.
 var codec = load("res://scripts/run_save_codec.gd")
 for old in ["gun","katana"]:
  var saved = codec.capture(game)
  saved["run"]["equipped_weapon_id"] = old
  saved["run"]["weapon_levels"] = {old:4,"sword":2,"bow":3}
  saved["run"]["elapsed_time"] = 325.0
  saved["combat"]["empowered"] = 5.0
  saved["combat"]["charge_ready"] = true
  saved["charge_targets"] = [{"remaining":2.0}]
  codec.restore_run(game,saved)
  codec.restore_world(game,saved)
  assert(combat.weapon_id == "sword" and run.weapon_level("sword") == 4)
  assert(run.weapon_level("bow") == 3 and run.elapsed_time == 325.0)
  assert(not run.weapon_levels.has("gun") and not run.weapon_levels.has("katana"))
  assert(not combat.charge_ready and combat.empowered == 0.0)
  assert(get_nodes_in_group("gun_charge_targets").is_empty())
 assert(run.catalog.data["weapons"].size() == 3)
 print("PASS: only sword/bow/spellbook; LV1 hold repeats; release stops; bow auto-resumes after reload; pause cancels hold; removed equip rejected; legacy gun/katana saves migrate with levels intact")
 game.queue_free()
 await process_frame
 await process_frame
 quit()