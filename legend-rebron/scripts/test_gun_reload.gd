extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("check_reload")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
func check_reload() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await process_frame
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	var run = game.get_node("RunState")
	var data = root.get_node("GameData")
	data.settings_path = "user://reload_test.cfg"
	data.restore_defaults()
	combat.equip("gun")
	check(not combat.try_reload(), "Full magazine does not reload")
	combat.gun_ammo = 6
	await key(KEY_R, true)
	await key(KEY_R, false)
	check(combat.gun_reload > 0.0 and combat.gun_ammo == 6, "R starts timed reload")
	check(not combat.try_attack() and not combat.try_reload(), "Reload blocks attack and duplicate reload")
	run.weapon_levels["gun"] = 3
	combat.charge_time = 1.0
	combat.release_charge()
	check(combat.gun_reload > 0.0 and combat.empowered == 0.0, "Charge release cannot bypass reload")
	for i in range(100):
		await physics_frame
	check(combat.gun_reload == 0.0 and combat.gun_ammo == 12, "Reload restores full magazine")
	combat.equip("sword")
	check(not combat.try_reload(), "Other weapons do not reload")
	combat.equip("gun")
	combat.gun_ammo = 4
	game.command_console.open_console()
	await key(KEY_R, true)
	await key(KEY_R, false)
	check(combat.gun_reload == 0.0 and not combat.try_reload(), "Console typing does not reload")
	game.command_console.close_console()
	game.get_node("Interface/PauseOverlay").toggle_pause()
	check(not combat.try_reload(), "Paused game does not reload")
	game.get_node("Interface/PauseOverlay").toggle_pause()
	check(combat.try_reload(), "Reload works after resuming")
	combat.gun_reload = 0.0
	data.rebind("reload", KEY_E)
	await key(KEY_R, true)
	await key(KEY_R, false)
	check(combat.gun_reload == 0.0, "Old reload binding disabled")
	await key(KEY_E, true)
	await key(KEY_E, false)
	check(combat.gun_reload > 0.0, "Remapped reload binding works")
	if not failed:
		print("PASS: R reload, magazine refill, full magazine guard, attack/charge guards, non-gun guard, console/pause safety and rebinding")
	quit(1 if failed else 0)