extends SceneTree
var failures: int = 0
var checks: int = 0
var session: Node

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run_tests")

func wait_world() -> void:
	for index in range(300):
		await process_frame
		if is_instance_valid(session.player) and not session.transitioning:
			break
	await create_timer(1.0).timeout

func key(code: int) -> void:
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
	session.save_path = "C:/Windows/Temp/legend-reborn-menu/test-save-%d.cfg" % Time.get_ticks_usec()
	session.settings_path = "C:/Windows/Temp/legend-reborn-menu/test-settings-%d.cfg" % Time.get_ticks_usec()
	session.legacy_path = "C:/Windows/Temp/legend-reborn-menu/no-legacy.cfg"
	session.progression().persistence_enabled = false
	var main = load(session.MAIN_MENU).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	check(main.continue_button.disabled, "Continue disabled when no save exists")
	check(not paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "title screen releases mouse")
	main.show_settings()
	check(main.page.visible and main.page.get_child_count() > 0, "title Settings page opens")
	main.back()
	main.show_controls()
	check(main.page.visible, "title Controls page opens")
	main.back()
	session.begin_new_game()
	await wait_world()
	check(current_scene.scene_file_path == session.WORLD, "New Game loads actual castle scene")
	check(session.progression().points == 3 and session.progression().level == 1, "New Game resets character build")
	var player = session.player
	var pause = session.pause_menu
	key(KEY_ESCAPE)
	await process_frame
	check(paused and pause.is_open, "Escape opens Pause instead of quitting")
	check(not player.get_node("CharacterStatsMenu").hud.visible and not player.get_node("GUI").visible, "Pause hides gameplay HUD behind menu")
	var location: Vector3 = player.global_position
	await create_timer(0.1, true).timeout
	check(player.global_position.is_equal_approx(location), "Pause freezes player simulation")
	key(KEY_C)
	await process_frame
	check(player.get_node("CharacterStatsMenu").opened, "Pause C opens existing stat panel")
	key(KEY_ESCAPE)
	await process_frame
	check(paused and pause.is_open and pause.overlay.visible, "closing stats returns to paused menu")
	pause.show_settings()
	check(pause.current_page == "settings", "Pause Settings opens")
	var master_slider = pause.content.find_child("master", true, false)
	master_slider.value = 22
	check(is_equal_approx(session.settings.master, 0.22), "Settings slider changes actual preference")
	var invert_toggle = pause.content.find_child("invert_y", true, false)
	invert_toggle.button_pressed = true
	check(session.settings.invert_y, "Settings toggle changes actual preference")
	session.persistence_enabled = true
	session.set_option("master", 0.25)
	session.set_option("music", 0.35)
	session.set_option("effects", 0.45)
	session.set_option("sensitivity", 21.0)
	session.set_option("invert_y", true)
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.25), "master volume affects audio bus")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.35), "music volume affects Music bus")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))), 0.45), "effects volume affects SFX bus")
	var camera = get_first_node_in_group("follow_camera")
	check(camera.mouse_sensitivity == 21.0 and camera.invert_y, "camera settings apply to gameplay camera")
	session.settings.master = 1.0
	session.load_settings()
	check(is_equal_approx(session.settings.master, 0.25), "settings round-trip to disk")
	pause.show_inventory()
	check(pause.current_page == "inventory", "Inventory page opens")
	pause.equip_item(1)
	check(player.inventory_system.current_item.item_name == "FireBomb" and player.current_item.item_name == "FireBomb", "Inventory equips selected item in gameplay")
	var wanted_weapon: String = player.weapon_system.stored_mount_point.get_child(0).equipment_info.name
	session.restore_equipment(player.weapon_system, wanted_weapon)
	check(player.weapon_system.current_equipment.equipment_info.name == wanted_weapon, "equipment swap changes held weapon")
	pause.show_pause()
	pause.confirm_exit(false)
	check(pause.dialog.visible, "return-to-menu requires confirmation")
	pause.dialog.hide()
	check(current_scene.scene_file_path == session.WORLD, "cancelled return keeps current game")
	player.inventory_system.inventory[0].count = 2
	player.inventory_system.inventory[1].count = 1
	session.progression().ranks.Hp = 2
	session.progression().changed.emit()
	player.health_system.current_health = 73.0
	player.stats.stamina = 41.0
	session.last_ground_position = player.global_position
	var enemy = get_first_node_in_group("targets")
	var defeated_path: String = str(current_scene.get_path_to(enemy))
	enemy.ragdoll_death = false
	enemy.death()
	var interacted: Node
	for object in get_nodes_in_group("interactable"):
		if "opened" in object and "locked" in object:
			interacted = object
			break
	var object_path: String = str(current_scene.get_path_to(interacted))
	interacted.opened = true
	interacted.locked = false
	check(session.save_game(), "Save Game writes complete save slot")
	check(session.save_game(), "saving again atomically replaces existing slot")
	var valid_path: String = session.save_path
	session.save_path = "C:/Windows/Temp/legend-reborn-menu/nonexistent-folder/save.cfg"
	check(not session.save_game(), "unwritable save location reports failure")
	check(not session.return_to_menu() and is_instance_valid(session.player), "save failure does not discard the running game")
	session.save_path = valid_path
	var snapshot: Dictionary = session.read_save()
	check(snapshot.character.ranks.Hp == 2 and snapshot.health == 73.0, "save contains build and health")
	check(snapshot.inventory[0].count == 2 and snapshot.weapon == wanted_weapon, "save contains inventory and equipped weapon")
	check(defeated_path in snapshot.defeated, "save records defeated enemies")
	check(session.return_to_menu(), "Save and Return succeeds")
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == session.MAIN_MENU and not paused, "main menu restored without stuck pause state")
	check(current_scene.continue_button.disabled == false, "Continue enabled for saved journey")
	current_scene.new_game()
	check(current_scene.dialog.visible, "New Game confirms before replacing a save")
	current_scene.dialog.hide()
	session.continue_game()
	await wait_world()
	player = session.player
	pause.open_menu()
	check(session.progression().ranks.Hp == 2 and player.health_system.total_health == 140, "Continue restores upgraded character")
	check(is_equal_approx(player.health_system.current_health, 73.0), "Continue restores current health")
	check(player.inventory_system.inventory[0].item_name == "FireBomb" and player.inventory_system.inventory[0].count == 2, "Continue restores item selection and counts")
	check(player.weapon_system.current_equipment.equipment_info.name == wanted_weapon, "Continue restores equipped weapon")
	check(current_scene.get_node_or_null(defeated_path) == null, "defeated enemy remains defeated after Continue")
	check(current_scene.get_node(object_path).opened, "Continue restores opened interactable")
	check(player.global_position.distance_to(snapshot.position) < 0.5, "Continue restores saved position")
	pause.resume_game()
	check(not paused and not pause.is_open, "Resume clears pause and hides menu")
	check(player.get_node("CharacterStatsMenu").hud.visible and player.get_node("GUI").visible, "Resume restores gameplay HUD")
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_START
	joy.pressed = true
	Input.parse_input_event(joy)
	await process_frame
	check(paused and pause.is_open, "controller Start opens Pause")
	pause.show_controls()
	key(KEY_ESCAPE)
	await process_frame
	check(pause.current_page == "pause" and paused, "Escape from subpage returns to Pause")
	pause.resume_game()
	session.persistence_enabled = false
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
