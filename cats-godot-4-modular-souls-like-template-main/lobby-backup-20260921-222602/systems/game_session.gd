extends Node
## Owns scene transitions, a complete local save slot, and persistent preferences.
signal saved(success: bool)
signal settings_changed
const WORLD = "res://demo_level/world_castle.tscn"
const MAIN_MENU = "res://ui/menus/main_menu.tscn"
var save_path: String = "user://legend_reborn_save.cfg"
var legacy_path: String = "user://character_progression.cfg"
var settings_path: String = "user://legend_reborn_settings.cfg"
var persistence_enabled: bool = true
var player: Node
var pause_menu: Node
var pending_restore: Dictionary = {}
var defeated: Array[String] = []
var play_seconds: float = 0.0
var auto_save_time: float = 0.0
var last_ground_position: Vector3 = Vector3.ZERO
var transitioning: bool = false
var last_error: String = ""
var settings: Dictionary = {"master": 0.7, "music": 0.6, "effects": 0.85, "fullscreen": false, "vsync": true, "sensitivity": 15.0, "invert_y": false}
const DEFAULT_SETTINGS = {"master": 0.7, "music": 0.6, "effects": 0.85, "fullscreen": false, "vsync": true, "sensitivity": 15.0, "invert_y": false}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	setup_audio()
	load_settings()
	apply_settings()
	pause_menu = preload("res://ui/menus/pause_menu.gd").new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	get_tree().node_added.connect(route_audio)

func setup_audio() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	var echo: int = AudioServer.get_bus_index("Echo")
	if echo >= 0:
		AudioServer.set_bus_send(echo, "SFX")

func route_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
		if node.bus == &"Master":
			node.bus = &"Music" if "Music" in str(node.name) else &"SFX"

func progression() -> Node:
	return get_node("/root/CharacterProgression")

func character_data() -> Dictionary:
	var p = progression()
	return {"level": p.level, "experience": p.experience, "points": p.points, "ranks": p.ranks.duplicate(true)}

func restore_character(data: Dictionary) -> void:
	var p = progression()
	p.level = clampi(int(data.get("level", 1)), 1, 100000)
	p.experience = clampi(int(data.get("experience", 0)), 0, p.xp_required() - 1)
	p.points = clampi(int(data.get("points", 3)), 0, 1000000)
	var ranks: Dictionary = data.get("ranks", {})
	for stat in p.KEYS:
		p.ranks[stat] = clampi(int(ranks.get(stat, 0)), 0, p.MAX_RANK)
	p.changed.emit()

func read_save() -> Dictionary:
	var file := ConfigFile.new()
	if file.load(save_path) != OK:
		return {}
	var data = file.get_value("save", "data", {})
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		return {}
	if data.get("scene", "") != WORLD or not data.get("character", null) is Dictionary:
		return {}
	if not data.get("position", null) is Vector3 or not data.get("inventory", null) is Array:
		return {}
	return data

func has_legacy_progress() -> bool:
	var config := ConfigFile.new()
	return config.load(legacy_path) == OK and config.has_section_key("character", "level")

func has_save() -> bool:
	return not read_save().is_empty() or has_legacy_progress()

func save_summary() -> String:
	var data: Dictionary = read_save()
	if data.is_empty():
		return "Existing character  /  Level %d\nContinue from the castle entrance." % progression().level if has_legacy_progress() else "No saved journey yet."
	var minutes: int = int(float(data.get("play_seconds", 0)) / 60.0)
	return "CASTLE OUTSKIRTS  /  LEVEL %d\n%dh %02dm played  /  Saved %s" % [data.character.level, int(minutes / 60.0), minutes % 60, data.get("saved_at", "")]

func begin_new_game() -> void:
	if transitioning:
		return
	# Keep a recoverable copy when the user confirms replacing their current game.
	if persistence_enabled and FileAccess.file_exists(save_path):
		if DirAccess.copy_absolute(save_path, save_path + ".previous") != OK:
			last_error = "Could not back up the current save. New game was not started."
			return
	if persistence_enabled and FileAccess.file_exists(progression().SAVE_PATH):
		DirAccess.copy_absolute(progression().SAVE_PATH, progression().SAVE_PATH + ".previous")
	restore_character({})
	defeated.clear()
	play_seconds = 0.0
	pending_restore.clear()
	start_world()

func continue_game() -> void:
	if transitioning:
		return
	var data := read_save()
	if data.is_empty():
		if not has_legacy_progress():
			last_error = "No readable save found. Start a new game."
			return
		progression().load_progress()
		pending_restore.clear()
	else:
		restore_character(data.character)
		pending_restore = data
		play_seconds = float(data.get("play_seconds", 0))
		defeated.assign(data.get("defeated", []))
	start_world()

func start_world() -> void:
	transitioning = true
	pause_menu.dismiss()
	get_tree().paused = false
	player = null
	await get_tree().process_frame
	var error: Error = get_tree().change_scene_to_file(WORLD)
	if error != OK:
		transitioning = false
		last_error = "The game scene could not be loaded."

func register_player(new_player: Node) -> void:
	player = new_player
	last_ground_position = player.global_position
	# Inventory restacking and animation initialization finish across these frames.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(player) or player != new_player:
		return
	if not pending_restore.is_empty():
		restore_world(pending_restore)
		pending_restore.clear()
	else:
		# Ordinary death/rest resets the castle, while retaining the character build.
		defeated.clear()
	transitioning = false
	apply_camera_settings()
	auto_save_time = 0.0
	if persistence_enabled:
		save_game()

func inventory_data() -> Array:
	var result: Array = []
	for item in player.inventory_system.inventory:
		result.append({"path": item.get_meta("source_path", item.resource_path), "count": item.count})
	return result

func capture_world() -> Dictionary:
	var enemies: Dictionary = {}
	var interactables: Dictionary = {}
	var scene = get_tree().current_scene
	for enemy in get_tree().get_nodes_in_group("targets"):
		if enemy.get("health_system") != null:
			enemies[str(scene.get_path_to(enemy))] = {"health": enemy.health_system.current_health, "position": enemy.global_position}
	for object in get_tree().get_nodes_in_group("interactable"):
		if not "opened" in object:
			continue
		var state: Dictionary = {"opened": object.opened}
		if "locked" in object:
			state.locked = object.locked
		if "anim" in object and object.anim is String:
			state.animation = object.anim
		interactables[str(scene.get_path_to(object))] = state
	var position: Vector3 = last_ground_position
	if player.is_on_floor() and player.current_state == player.state.FREE and not player.busy:
		position = player.global_position
	return {"version": 1, "scene": WORLD, "saved_at": Time.get_datetime_string_from_system().replace("T", " "), "play_seconds": play_seconds, "character": character_data(), "position": position, "rotation": player.rotation.y, "health": player.health_system.current_health, "stamina": player.stats.stamina, "inventory": inventory_data(), "weapon": player.weapon_system.current_equipment.equipment_info.name, "gadget": player.gadget_system.current_equipment.equipment_info.name, "defeated": defeated.duplicate(), "enemies": enemies, "interactables": interactables}

func save_game() -> bool:
	if not is_instance_valid(player) or player.is_dead:
		last_error = "Your last save is preserved. Wait until you respawn to save again."
		return false
	var config := ConfigFile.new()
	config.set_value("save", "data", capture_world())
	if not persistence_enabled:
		return true
	# Write the replacement completely before renaming it over the current slot.
	var error: Error = config.save(save_path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if error != OK:
		last_error = "Save failed. Check that the save folder is writable."
		saved.emit(false)
		return false
	progression().save_progress()
	last_error = ""
	auto_save_time = 0.0
	saved.emit(true)
	return true

func restore_world(data: Dictionary) -> void:
	player.global_position = data.position
	last_ground_position = data.position
	player.rotation.y = float(data.get("rotation", 0.0))
	player.velocity = Vector3.ZERO
	player.health_system.current_health = clampf(float(data.get("health", 100)), 1, player.health_system.total_health)
	player.health_system.health_updated.emit(player.health_system.current_health)
	player.stats.stamina = clampf(float(data.get("stamina", 100)), 0, progression().value("Stamina"))
	player.stats.stamina_changed.emit()
	var items: Array = []
	for entry in data.get("inventory", []):
		if not entry is Dictionary:
			continue
		var path: String = str(entry.get("path", ""))
		if path not in ["res://player/item_system/items/potion.tres", "res://player/item_system/items/firebomb.tres"]:
			continue
		var item = load(path).duplicate()
		item.set_meta("source_path", path)
		item.count = clampi(int(entry.get("count", 0)), 0, 9999)
		items.append(item)
	if not items.is_empty():
		player.inventory_system.inventory = items
		player.inventory_system.current_item = items[0]
		player.current_item = items[0]
		player.inventory_system.inventory_updated.emit(items)
		player.item_change_ended.emit(items[0])
	restore_equipment(player.weapon_system, str(data.get("weapon", "")))
	restore_equipment(player.gadget_system, str(data.get("gadget", "")))
	var scene = get_tree().current_scene
	for path in data.get("defeated", []):
		var enemy = scene.get_node_or_null(NodePath(path))
		if enemy:
			enemy.remove_from_group("targets")
			enemy.queue_free()
	for path in data.get("enemies", {}):
		var enemy = scene.get_node_or_null(NodePath(path))
		if enemy and not enemy.is_queued_for_deletion():
			var state: Dictionary = data.enemies[path]
			enemy.health_system.current_health = clampf(float(state.get("health", 5)), 0.01, enemy.health_system.total_health)
			enemy.health_system.health_updated.emit(enemy.health_system.current_health)
			if state.get("position") is Vector3:
				enemy.global_position = state.position
	for path in data.get("interactables", {}):
		var object = scene.get_node_or_null(NodePath(path))
		if not object:
			continue
		var state: Dictionary = data.interactables[path]
		object.opened = bool(state.get("opened", false))
		if "locked" in object:
			object.locked = bool(state.get("locked", false))
		if object.opened:
			var animation_name: String = str(state.get("animation", "open"))
			if "anim" in object:
				object.anim = animation_name
			for child in object.get_children():
				if child is AnimationPlayer and child.has_animation(animation_name):
					child.play(animation_name)
					child.seek(child.get_animation(animation_name).length, true)
					child.pause()
	# The camera uses a world-space spring arm, so reset its follow position too.
	for camera in get_tree().get_nodes_in_group("follow_camera"):
		camera.global_position = player.global_position + Vector3(0, camera.vertical_offset, 0)

func restore_equipment(system: Node, equipment_name: String) -> void:
	if equipment_name.is_empty() or system.current_equipment.equipment_info.name == equipment_name:
		return
	var held = system.current_equipment
	var stored = system.stored_mount_point.get_child(0)
	if stored.equipment_info.name != equipment_name:
		return
	if held.body_entered.is_connected(system._on_body_entered):
		held.body_entered.disconnect(system._on_body_entered)
	held.reparent(system.stored_mount_point, false)
	stored.reparent(system.held_mount_point, false)
	held.equipped = false
	stored.equipped = true
	stored.monitoring = false
	stored.collision_mask = system.collision_detect_layers
	if not stored.body_entered.is_connected(system._on_body_entered):
		stored.body_entered.connect(system._on_body_entered)
	system.current_equipment = stored
	system.stored_equipment = held
	system.equipment_changed.emit(stored)
	player.weapon_change_ended.emit(player.weapon_type)
	player.gadget_change_ended.emit(player.gadget_type)

func record_defeat(enemy: Node) -> void:
	var path: String = str(get_tree().current_scene.get_path_to(enemy))
	if path not in defeated:
		defeated.append(path)

func return_to_menu() -> bool:
	if is_instance_valid(player) and not player.is_dead and not save_game():
		return false
	pause_menu.dismiss()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player = null
	pending_restore.clear()
	transitioning = false
	get_tree().change_scene_to_file(MAIN_MENU)
	return true

func quit_game() -> void:
	if is_instance_valid(player) and not player.is_dead and not save_game():
		pause_menu.show_error(last_error)
		return
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(player):
			pause_menu.open_menu()
			pause_menu.confirm_exit(true)
		else:
			get_tree().quit()

func _process(delta: float) -> void:
	if is_instance_valid(player) and not transitioning and not get_tree().paused and not player.is_dead:
		play_seconds += delta
		auto_save_time += delta
		if player.is_on_floor() and player.current_state == player.state.FREE and not player.busy:
			last_ground_position = player.global_position
			if auto_save_time >= 60.0 and persistence_enabled:
				save_game()

func set_option(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	apply_settings()
	save_settings()
	settings_changed.emit()

func apply_settings() -> void:
	for entry in [["Master", "master"], ["Music", "music"], ["SFX", "effects"]]:
		var index: int = AudioServer.get_bus_index(entry[0])
		var volume: float = clampf(float(settings[entry[1]]), 0, 1)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, volume)))
		AudioServer.set_bus_mute(index, volume <= 0)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	apply_camera_settings()

func apply_camera_settings() -> void:
	for camera in get_tree().get_nodes_in_group("follow_camera"):
		camera.mouse_sensitivity = float(settings.sensitivity)
		camera.invert_y = bool(settings.invert_y)

func save_settings() -> bool:
	if not persistence_enabled:
		return true
	var config := ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	var result: bool = config.save(settings_path) == OK
	if not result:
		last_error = "Settings could not be saved to disk."
	return result

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	for key in settings:
		var value = config.get_value("settings", key, settings[key])
		if key in ["master", "music", "effects"]:
			settings[key] = clampf(float(value), 0, 1)
		elif key == "sensitivity":
			settings[key] = clampf(float(value), 1, 50)
		else:
			settings[key] = bool(value)
