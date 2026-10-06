extends Node
signal settings_changed
signal characters_changed
const CHARACTERS := ["Daddy", "Mommy", "Son"]
var progress_path := "user://progress.cfg"
var unlocked_characters: Array[String] = ["Daddy"]
const SAVE_PATH := "user://settings.cfg"
const ACTIONS = {
	"move_forward": {"label": "Move forward", "key": KEY_W},
	"move_back": {"label": "Move backward", "key": KEY_S},
	"move_left": {"label": "Strafe left", "key": KEY_A},
	"move_right": {"label": "Strafe right", "key": KEY_D},
	"jump": {"label": "Jump", "key": KEY_SPACE},
	"sprint": {"label": "Sprint (hold)", "key": KEY_SHIFT},
	"dash": {"label": "Dash", "key": KEY_Q},
	"toggle_cursor": {"label": "Stats & equipment (hold)", "key": KEY_TAB},
	"reload": {"label": "Reload weapon", "key": KEY_R}

}
const CROSSHAIR_COLORS = {
	"white": Color.WHITE, "red": Color("ff3535"), "black": Color.BLACK,
	"blue": Color("50bfff"), "yellow": Color("ffe23a")
}
const CROSSHAIR_STYLES = ["plus", "dot", "gap"]
var settings_path := SAVE_PATH
var selected_character := "Daddy"
var games_completed := 0
var master_volume := 0.8
var music_volume := 0.7
var effects_volume := 0.8
var mouse_sensitivity := 0.5
var fullscreen := false
var invert_y := false
var crosshair_style := "plus"
var crosshair_color := "white"
var crosshair_size := 16.0
var tab_ui_opacity := 0.65
var bindings: Dictionary = {}
var rebinding_active := false
var command_console_active := false
func _ready() -> void:
	bindings = default_bindings()
	load_settings()
	load_progress()
	apply_settings()
func default_bindings() -> Dictionary:
	var result: Dictionary = {}
	for action in ACTIONS:
		result[action] = ACTIONS[action]["key"]
	return result
func key_label(action: String) -> String:
	return OS.get_keycode_string(int(bindings.get(action, ACTIONS[action]["key"])))
func rebuild_input_map() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		Input.action_release(action)
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = int(bindings[action])
		InputMap.action_add_event(action, event)
func rebind(action: String, keycode: int) -> String:
	if not ACTIONS.has(action) or keycode == KEY_NONE or keycode in [KEY_ESCAPE, KEY_F1]:
		return "Escape and F1 are reserved for pause / console."
	var old_key: int = bindings[action]
	var message := "%s: %s" % [ACTIONS[action]["label"], OS.get_keycode_string(keycode)]
	for other in bindings:
		if other != action and bindings[other] == keycode:
			bindings[other] = old_key
			message += " / swapped with " + ACTIONS[other]["label"]
			break
	bindings[action] = keycode
	rebuild_input_map()
	save_settings()
	settings_changed.emit()
	return message
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "effects", effects_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("ui", "tab_opacity", tab_ui_opacity)
	cfg.set_value("crosshair", "style", crosshair_style)
	cfg.set_value("crosshair", "color", crosshair_color)
	cfg.set_value("crosshair", "size", crosshair_size)
	for action in bindings:
		cfg.set_value("bindings", action, bindings[action])
	cfg.save(settings_path)
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) != OK:
		return
	master_volume = clampf(float(cfg.get_value("audio", "master", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music", music_volume)), 0.0, 1.0)
	effects_volume = clampf(float(cfg.get_value("audio", "effects", effects_volume)), 0.0, 1.0)
	mouse_sensitivity = clampf(float(cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)), 0.01, 1.0)
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	tab_ui_opacity = clampf(float(cfg.get_value("ui", "tab_opacity", 0.65)), 0.0, 1.0)
	invert_y = bool(cfg.get_value("controls", "invert_y", invert_y))
	var saved_style: String = cfg.get_value("crosshair", "style", "plus")
	crosshair_style = saved_style if CROSSHAIR_STYLES.has(saved_style) else "plus"
	var saved_color: String = cfg.get_value("crosshair", "color", "white")
	crosshair_color = saved_color if CROSSHAIR_COLORS.has(saved_color) else "white"
	crosshair_size = clampf(float(cfg.get_value("crosshair", "size", 16.0)), 6.0, 48.0)
	# Load through swaps so every action keeps a unique valid key.
	bindings = default_bindings()
	for action in ACTIONS:
		var keycode := int(cfg.get_value("bindings", action, bindings[action]))
		if keycode <= 0 or keycode in [KEY_ESCAPE, KEY_F1]:
			continue
		var previous: int = bindings[action]
		for other in bindings:
			if other != action and bindings[other] == keycode:
				bindings[other] = previous
				break
		bindings[action] = keycode
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)
	rebuild_input_map()
	settings_changed.emit()
func restore_defaults() -> void:
	master_volume = 0.8
	music_volume = 0.7
	effects_volume = 0.8
	mouse_sensitivity = 0.5
	fullscreen = false
	invert_y = false
	crosshair_style = "plus"
	crosshair_color = "white"
	crosshair_size = 16.0
	tab_ui_opacity = 0.65
	bindings = default_bindings()
	apply_settings()
	save_settings()

func is_character_unlocked(character: String) -> bool:
	return unlocked_characters.has(character) or (character == "Mommy" and games_completed >= 1)

func unlock_character(character: String) -> bool:
	if character not in CHARACTERS:
		return false
	if not unlocked_characters.has(character):
		unlocked_characters.append(character)
	save_progress()
	characters_changed.emit()
	return true

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("characters", "unlocked", unlocked_characters)
	cfg.set_value("progress", "games_completed", games_completed)
	cfg.save(progress_path)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(progress_path) != OK:
		return
	unlocked_characters.assign(["Daddy"])
	for character in cfg.get_value("characters", "unlocked", []):
		if character in CHARACTERS and not unlocked_characters.has(character):
			unlocked_characters.append(character)
	games_completed = maxi(0, int(cfg.get_value("progress", "games_completed", 0)))
