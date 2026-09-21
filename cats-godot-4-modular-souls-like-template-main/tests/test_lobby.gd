extends SceneTree
var failures: int = 0
var count: int = 0
var session: Node

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	count += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func wait_scene() -> void:
	for index in range(360):
		await process_frame
		if is_instance_valid(session.player) and not session.transitioning:
			break
	await create_timer(0.9).timeout

func press(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func run_tests() -> void:
	session = root.get_node("GameSession")
	session.persistence_enabled = false
	session.progression().persistence_enabled = false
	session.legacy_path = "C:/Windows/Temp/legend-reborn-lobby/no-legacy.cfg"
	session.save_path = "C:/Windows/Temp/legend-reborn-lobby/test-save-%d.cfg" % Time.get_ticks_usec()
	session.begin_new_game()
	await wait_scene()
	check(current_scene.scene_file_path == session.HOME, "New Game arrives at Home")
	check(session.area_name() == "Ashen Refuge", "Home location name")
	var lobby = current_scene
	var player = session.player
	check(player.is_on_floor(), "lobby floor supports the player")
	check(get_nodes_in_group("targets").is_empty(), "lobby has no combat enemies")
	check(lobby.get_node("QuestBoard").get_meta("available") == false, "quest board is marked unavailable")
	check(not lobby.get_node("QuestBoard").has_method("activate"), "quest board has no interaction action")
	check(lobby.get_node("Merchant").get_meta("available") == false, "merchant is marked unavailable")
	check(not lobby.get_node("Merchant").has_method("activate"), "merchant has no purchase interaction")
	check(not lobby.try_enter_dungeon(), "cannot enter dungeon from across the lobby")
	player.global_position = Vector3(-7.3, 0.1, -2.5)
	press(KEY_E)
	await process_frame
	check(current_scene == lobby and not session.transitioning, "E near quest board does not open anything")
	player.global_position = Vector3(7.4, 0.1, -2.5)
	press(KEY_E)
	await process_frame
	check(current_scene == lobby and not session.transitioning, "E near merchant does not open anything")
	press(KEY_ESCAPE)
	await process_frame
	check(paused and session.pause_menu.is_open, "Pause works in Home")
	press(KEY_ESCAPE)
	await process_frame
	check(not paused, "Home resumes after Pause")
	player.health_system.current_health = 81.0
	player.inventory_system.inventory[0].count = 2
	player.global_position = Vector3(0, 0.15, -6.0)
	player.velocity = Vector3.ZERO
	for index in range(8):
		await physics_frame
	check(lobby.near_gate(), "gate detects nearby player")
	player.busy = true
	check(not lobby.try_enter_dungeon(), "cannot travel during an active action")
	player.busy = false
	press(KEY_E)
	await wait_scene()
	check(current_scene.scene_file_path == session.WORLD, "E at gate loads real dungeon")
	check(session.player.health_system.current_health == 81.0, "health travels from Home to dungeon")
	check(session.player.inventory_system.inventory[0].count == 2, "item counts travel from Home to dungeon")
	check(not session.enter_dungeon(), "gate travel cannot be invoked from the dungeon")
	player = session.player
	player.health_system.current_health = 67
	player.inventory_system.inventory[0].count = 1
	var enemy = get_first_node_in_group("targets")
	var enemy_path: String = str(current_scene.get_path_to(enemy))
	enemy.ragdoll_death = false
	enemy.death()
	session.persistence_enabled = true
	session.pause_menu.open_menu()
	check(session.return_home(), "dungeon can return to Home through Pause")
	await wait_scene()
	check(current_scene.scene_file_path == session.HOME and not paused, "returning Home clears pause state")
	check(session.player.health_system.current_health == 67, "returning Home preserves current health")
	check(session.player.inventory_system.inventory[0].count == 1, "returning Home preserves consumed items")
	check(enemy_path in session.dungeon_state.defeated, "dungeon defeat state archived while at Home")
	check(session.save_game(), "Home can be saved")
	var snapshot: Dictionary = session.read_save()
	check(snapshot.scene == session.HOME and enemy_path in snapshot.dungeon.defeated, "Home save embeds dungeon progress")
	check(session.return_to_menu(), "Home can return to main menu")
	await process_frame
	await process_frame
	session.continue_game()
	await wait_scene()
	check(current_scene.scene_file_path == session.HOME, "Continue arrives at Home")
	check(enemy_path in session.dungeon_state.defeated, "Continue keeps archived dungeon progress")
	session.player.global_position = Vector3(0, 0.15, -6.0)
	press(KEY_E)
	await wait_scene()
	check(current_scene.scene_file_path == session.WORLD, "gate works again after Continue")
	check(current_scene.get_node_or_null(enemy_path) == null, "defeated enemy stays defeated on re-entry")
	check(session.player.inventory_system.inventory[0].count == 1, "re-entry does not duplicate consumables")
	check(session.save_game(), "dungeon save remains valid")
	var old_format: Dictionary = session.read_save()
	old_format.erase("dungeon")
	var fixture := ConfigFile.new()
	fixture.set_value("save", "data", old_format)
	var fixture_path: String = session.save_path + ".legacy"
	fixture.save(fixture_path)
	session.persistence_enabled = false
	session.return_to_menu()
	await process_frame
	await process_frame
	session.save_path = fixture_path
	session.continue_game()
	await wait_scene()
	check(current_scene.scene_file_path == session.HOME, "old dungeon-only save loads into Home")
	check(enemy_path in session.dungeon_state.defeated, "old dungeon-only save preserves progress")
	session.return_to_menu()
	await process_frame
	await process_frame
	session.begin_new_game()
	await wait_scene()
	check(session.dungeon_state.is_empty(), "New Game clears previous dungeon archive")
	check(session.progression().points == 3, "New Game still creates a fresh character")
	print("RESULT: %d checks, %d failures" % [count, failures])
	quit(1 if failures else 0)
