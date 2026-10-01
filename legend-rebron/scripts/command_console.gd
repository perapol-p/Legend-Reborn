extends PanelContainer
const Style = preload("res://scripts/ui_style.gd")
const HELP := "/help — list commands\n/weapon <sword|katana|gun|bow|spellbook> — equip weapon\n/target — create training target\n/hit — test combo hit\n/kill — test combo kill\n/reset — reset combo\n/levelup — level up and choose an item\n/weaponlevel — upgrade current weapon (max 5)\n/spawndebug <on|off> — show/hide spawn ring and markers\n/spawninfo — show spawn counts and distance\n/clear — clear console"
var game: Node
var output: RichTextLabel
var entry: LineEdit
var history: Array[String] = []
var history_index := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 24
	offset_right = -24
	offset_top = 16
	offset_bottom = 300
	add_theme_stylebox_override("panel", Style.box(Color(0.06, 0.08, 0.10, 0.96), Style.GOLD))
	var stack := VBoxContainer.new()
	add_child(stack)
	Style.label(stack, "COMMAND CONSOLE  /  F1 or Esc to close", 18, Style.GOLD)
	output = RichTextLabel.new()
	output.custom_minimum_size.y = 210
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.scroll_following = true
	output.bbcode_enabled = false
	output.add_theme_font_size_override("normal_font_size", 16)
	stack.add_child(output)
	entry = LineEdit.new()
	entry.placeholder_text = "Type /help for commands, then press Enter"
	stack.add_child(entry)
	entry.text_submitted.connect(submit)
	entry.gui_input.connect(_entry_input)
	hide()
	write("Type /help to list commands.")
func write(message: String) -> void:
	output.add_text(message + "\n")
	if output.get_line_count() > 250:
		output.clear()
		output.add_text(message + "\n")
func open_console() -> void:
	if GameData.rebinding_active:
		return
	show()
	GameData.command_console_active = true
	game._sync_reward()
	entry.grab_focus()
func close_console() -> void:
	hide()
	GameData.command_console_active = false
	entry.release_focus()
	game._sync_reward()
	var pause = game.get_node("Interface/PauseOverlay")
	var reward = game.get_node("Interface/RewardOverlay")
	if reward.visible and not reward.choice_buttons.is_empty():
		reward.choice_buttons[0].grab_focus()
	elif pause.visible:
		pause.resume.grab_focus()
func _input(event: InputEvent) -> void:
	if GameData.rebinding_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			if visible:
				close_console()
			else:
				open_console()
			get_viewport().set_input_as_handled()
		elif visible and event.physical_keycode == KEY_ESCAPE:
			close_console()
			get_viewport().set_input_as_handled()
func _entry_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_UP, KEY_DOWN]:
			history_index = clampi(history_index + (-1 if event.physical_keycode == KEY_UP else 1), 0, history.size())
			entry.text = history[history_index] if history_index < history.size() else ""
			entry.caret_column = entry.text.length()
			entry.accept_event()
func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
func submit(raw: String) -> void:
	var command := raw.strip_edges()
	entry.clear()
	if command.is_empty():
		return
	history.append(command)
	if history.size() > 100:
		history.pop_front()
	history_index = history.size()
	write("> " + command)
	var args := command.to_lower().split(" ", false)
	var name: String = args[0]
	var run = game.get_node("RunState")
	var combo = game.get_node("Combo")
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	var spawner = game.get_node("MonsterSpawner")
	if name == "/help" and args.size() == 1:
		write(HELP)
		return
	if name == "/clear" and args.size() == 1:
		output.clear()
		return
	if name == "/spawninfo" and args.size() == 1:
		write("Spawn radius: %.0f m | Alive: %d / %d | Last spawn: %.1f m | Total spawned: %d" % [spawner.spawn_radius, spawner.monsters.size(), spawner.max_alive, spawner.last_distance, spawner.total_spawned])
		return
	if not run.offers.is_empty():
		write("Choose your pending level-up item before using gameplay commands.")
		return
	match name:
		"/weapon":
			if args.size() != 2 or not combat.WEAPONS.has(args[1]):
				write("Usage: /weapon sword|katana|gun|bow|spellbook")
				return
			combat.equip(args[1])
			write("Equipped " + run.weapon_name())
		"/spawndebug":
			if args.size() != 2 or args[1] not in ["on", "off"]:
				write("Usage: /spawndebug on|off")
				return
			spawner.show_debug_radius = args[1] == "on"
			spawner.update_debug()
			write("Spawn debug " + args[1])
		"/target", "/hit", "/kill", "/reset", "/levelup", "/weaponlevel":
			if args.size() != 1:
				write("Usage: " + name)
				return
			match name:
				"/target": combat.spawn_target()
				"/hit": combo.register_hit()
				"/kill": combo.register_kill()
				"/reset": combo.reset()
				"/levelup": run.test_level_up()
				"/weaponlevel":
					if not run.upgrade_weapon():
						write("Weapon cannot be upgraded (max level 5).")
						return
			write("Done: " + name)
			if name == "/levelup":
				close_console()
		_: write("Unknown command. Type /help.")
func _exit_tree() -> void:
	GameData.command_console_active = false