extends ColorRect
const Style = preload("res://scripts/ui_style.gd")
var game: Node
var buttons: Dictionary = {}
var count: SpinBox
var output: RichTextLabel
var summary: Label
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.02,0.03,0.04,0.88)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -550
	panel.offset_right = 550
	panel.offset_top = -315
	panel.offset_bottom = 315
	panel.add_theme_stylebox_override("panel",Style.box(Style.INK,Style.GOLD))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",8)
	panel.add_child(stack)
	Style.label(stack,"PRACTICE TOOLS  /  U or Esc to close",26,Style.GOLD)
	summary = Style.label(stack,"",16)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",18)
	scroll.add_child(columns)
	var enemies := _column(columns,"ENEMIES")
	Style.label(enemies,"Spawn count (1-10)",16)
	count = SpinBox.new()
	count.min_value = 1
	count.max_value = 10
	count.value = 1
	count.step = 1
	enemies.add_child(count)
	for type in ["melee","archer","flyer","boss"]:
		_command_button(enemies,"Spawn " + type.capitalize(),"/spawn " + type)
	_command_button(enemies,"Create Training Target","/target")
	var weapons := _column(columns,"WEAPONS & LEVELS")
	var weapon_grid := GridContainer.new()
	weapon_grid.columns = 2
	weapon_grid.add_theme_constant_override("h_separation",6)
	weapon_grid.add_theme_constant_override("v_separation",6)
	weapons.add_child(weapon_grid)
	for id in ["sword","bow","spellbook"]:
		_command_button(weapon_grid,"Staff" if id == "spellbook" else id.capitalize(),"/weapon " + ("staff" if id == "spellbook" else id))
	_command_button(weapons,"Character Level +1 (Choose Item)","/levelup")
	_command_button(weapons,"Weapon Level +1","/weaponlevel")
	Style.label(weapons,"COMBO",18,Style.GOLD)
	_command_button(weapons,"Test Combo Hit (+1)","/hit")
	_command_button(weapons,"Test Combo Kill (+3)","/kill")
	_command_button(weapons,"Reset Combo","/reset")
	var utilities := _column(columns,"UTILITIES")
	var unlocks := GridContainer.new()
	unlocks.columns = 2
	unlocks.add_theme_constant_override("h_separation",6)
	unlocks.add_theme_constant_override("v_separation",6)
	utilities.add_child(unlocks)
	for id in ["Saber","Archer","Wizard god","All"]:
		_command_button(unlocks,"Unlock " + id,"/unlock " + id.to_lower())
	_command_button(utilities,"Show Spawn Debug","/spawndebug on")
	_command_button(utilities,"Hide Spawn Debug","/spawndebug off")
	_command_button(utilities,"Show Spawn Info","/spawninfo")
	_command_button(utilities,"Help / All Commands","/help")
	_command_button(utilities,"Clear Output","/clear")
	var text_console := Style.button(utilities,"Open Text Console (F1)",func():
		close_panel()
		game.command_console.open_console()
	)
	_compact_button(text_console)
	output = RichTextLabel.new()
	output.custom_minimum_size.y = 100
	output.scroll_following = true
	output.bbcode_enabled = false
	output.add_theme_font_size_override("normal_font_size",14)
	stack.add_child(output)
	Style.button(stack,"CLOSE / RESUME",close_panel)
	game.get_node("RunState").changed.connect(_refresh_summary)
	_refresh_summary()
	hide()
func _column(parent: Node, title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.custom_minimum_size.x = 330
	column.add_theme_constant_override("separation",6)
	parent.add_child(column)
	Style.label(column,title,18,Style.GOLD)
	return column
func _command_button(parent: Node, label: String, command: String) -> void:
	var button := Style.button(parent,label,func(): execute(command))
	button.custom_minimum_size = Vector2(160,35)
	_compact_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons[command] = button
func execute(command: String) -> void:
	if game.round_finished:
		return
	var actual := command
	if command.begins_with("/spawn "):
		actual += " " + str(int(count.value))
	if command == "/levelup":
		close_panel()
	game.command_console.submit(actual)
	output.text = game.command_console.output.get_parsed_text()
	if output.text.is_empty():
		output.text = "Output cleared."
	_refresh_summary()
func open_panel() -> void:
	if game.round_finished or GameData.rebinding_active or not game.get_node("RunState").offers.is_empty():
		return
	if game.command_console.visible:
		game.command_console.close_console()
	game.get_node("Interface/PauseOverlay").hide()
	show()
	GameData.practice_ui_active = true
	output.text = game.command_console.output.get_parsed_text()
	_refresh_summary()
	game._sync_reward()
	buttons["/spawn melee"].grab_focus()
func close_panel() -> void:
	hide()
	GameData.practice_ui_active = false
	game._sync_reward()
func _refresh_summary() -> void:
	var run = game.get_node("RunState")
	var spawner = game.get_node("MonsterSpawner")
	summary.text = "Character LV %d   /   %s LV %d   /   Enemies %d" % [run.level,run.weapon_name(),run.weapon_level(),spawner.monsters.size()]
func _input(event: InputEvent) -> void:
	if game.round_finished or GameData.rebinding_active:
		return
	if game.command_console.visible and not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_U:
			if visible:
				close_panel()
			else:
				open_panel()
			get_viewport().set_input_as_handled()
		elif visible and event.physical_keycode == KEY_ESCAPE:
			close_panel()
			get_viewport().set_input_as_handled()
		elif visible and event.physical_keycode == KEY_F1:
			close_panel()
			game.command_console.open_console()
			get_viewport().set_input_as_handled()
func _exit_tree() -> void:
	GameData.practice_ui_active = false

func _compact_button(button: Button) -> void:
	button.custom_minimum_size.y = 35
	button.add_theme_font_size_override("font_size",16)
	for name in ["normal","hover","pressed"]:
		var box := button.get_theme_stylebox(name).duplicate() as StyleBox
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		button.add_theme_stylebox_override(name,box)
