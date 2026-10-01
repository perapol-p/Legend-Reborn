extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("check_console")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
func key(code: int, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
func capture(name: String) -> void:
	for i in range(4):
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/" + name + ".png")
func check_console() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	current_scene = game
	await process_frame
	var console = game.command_console
	var run = game.get_node("RunState")
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	var combo = game.get_node("Combo")
	var spawner = game.get_node("MonsterSpawner")
	var player = game.get_node("Player")
	var data = root.get_node("GameData")
	check(not console.visible and not spawner.info.visible and not spawner.ring.visible, "Debug UI hidden initially")
	var weapon: String = combat.weapon_id
	for code in [KEY_2, KEY_T, KEY_J, KEY_K, KEY_R, KEY_L, KEY_U, KEY_B]:
		await key(code)
		await key(code, false)
	check(combat.weapon_id == weapon and not is_instance_valid(combat.dummy) and run.level == 1 and run.weapon_level() == 1 and combo.points == 0 and not spawner.ring.visible, "Old test shortcuts must do nothing")
	await capture("command_clean_hud")
	await key(KEY_F1)
	await key(KEY_F1, false)
	check(console.visible and paused and not player.input_enabled and console.entry.has_focus(), "F1 opens console and blocks gameplay")
	console.entry.text = "/help"
	console.entry.text_submitted.emit(console.entry.text)
	check(console.output.get_parsed_text().contains("/weaponlevel") and console.entry.text.is_empty(), "Help and submitted input")
	await capture("command_console_help")
	console.submit("/weapon gun")
	check(combat.weapon_id == "gun" and run.equipped_weapon_id == "gun", "Equip command")
	console.submit("/weapon bad")
	console.submit("/weapon gun extra")
	check(combat.weapon_id == "gun", "Invalid weapon arguments")
	console.submit("/weaponlevel")
	check(run.weapon_level() == 2, "Weapon upgrade command")
	console.submit("/hit")
	check(combo.points > 0, "Hit command")
	var points: int = combo.points
	console.submit("/kill")
	check(combo.points > points, "Kill command")
	console.submit("/reset")
	check(combo.points == 0, "Reset command")
	console.submit("/target")
	check(is_instance_valid(combat.dummy), "Target command")
	console.submit("/spawndebug on")
	check(spawner.ring.visible and not spawner.info.visible, "Debug ring command without HUD text")
	console.submit("/spawninfo")
	check(console.output.get_parsed_text().contains("Alive:"), "Spawn info in console")
	console.submit("/spawndebug off")
	check(not spawner.ring.visible, "Debug off command")
	console.submit("/invalid")
	check(console.output.get_parsed_text().contains("Unknown command"), "Unknown command feedback")
	await key(KEY_UP)
	await key(KEY_UP, false)
	check(console.entry.text == "/invalid", "Command history")
	console.submit("/levelup")
	check(run.level == 2 and not console.visible and paused and not run.offers.is_empty(), "Level-up opens reward and closes console")
	await key(KEY_F1)
	await key(KEY_F1, false)
	var count: int = run.total_items()
	await key(KEY_1)
	await key(KEY_1, false)
	check(run.total_items() == count and console.visible, "Console typing does not choose reward")
	console.submit("/hit")
	check(console.output.get_parsed_text().contains("pending level-up"), "Pending reward command guard")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	check(not console.visible and paused, "Esc closes console preserving reward pause")
	run.choose_item(run.offers[0])
	check(not paused and player.input_enabled, "Reward close restores gameplay")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	await key(KEY_F1)
	await key(KEY_F1, false)
	await key(KEY_F1)
	await key(KEY_F1, false)
	check(paused and game.get_node("Interface/PauseOverlay").visible, "Console preserves paused menu")
	game.get_node("Interface/PauseOverlay").toggle_pause()
	await key(KEY_TAB)
	check(paused and game.get_node("Interface/PauseOverlay").heading.text == "Stats", "Tab stats still work")
	await key(KEY_TAB, false)
	check(not paused and player.input_enabled, "Tab release still works")
	check(data.rebind("jump", KEY_F1).contains("reserved"), "F1 is reserved")
	if not failed:
		print("PASS: clean HUD, command-only debug actions, F1 console, help/history/errors, all commands, reward/pause/input safety and Tab stats")
	quit(1 if failed else 0)