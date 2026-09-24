extends Control
const Style = preload("res://scripts/ui_style.gd")
var content: VBoxContainer
var heading: Label
var resume: Button
func _ready() -> void:
	hide()
	var shade := ColorRect.new()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.035, 0.04, 0.86)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 32)
	layout.add_child(body)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size.x = 365
	menu.add_theme_constant_override("separation", 8)
	body.add_child(menu)
	Style.label(menu, "LEGEND REBORN", 22, Style.GOLD)
	Style.label(menu, "Paused", 58)
	resume = Style.button(menu, "Resume", toggle_pause)
	Style.button(menu, "Inventory & Equipment", show_inventory)
	Style.button(menu, "Settings", show_settings)
	Style.button(menu, "Controls", show_controls)
	Style.button(menu, "Return to Main Menu", return_to_menu)
	Style.button(menu, "Quit to Desktop", func(): get_tree().quit())
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", Style.box(Color("202429"), Color("57503e")))
	body.add_child(panel)
	var right := VBoxContainer.new()
	panel.add_child(right)
	heading = Style.label(right, "Stats", 30)
	var tabs := HBoxContainer.new()
	right.add_child(tabs)
	Style.button(tabs, "Primary", func(): show_stats(false))
	Style.button(tabs, "Secondary", func(): show_stats(true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var equipment := HBoxContainer.new()
	equipment.custom_minimum_size.y = 120
	equipment.add_theme_constant_override("separation", 16)
	layout.add_child(equipment)
	for title in ["WEAPON", "ITEMS"]:
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", Style.box(Color("25292e"), Style.GOLD))
		equipment.add_child(slot)
		var stack := VBoxContainer.new()
		slot.add_child(stack)
		Style.label(stack, title, 16, Style.GOLD)
		Style.label(stack, "PISTOL   /   10 : 10" if title == "WEAPON" else "[  —  ]    [  —  ]    [  —  ]    [  —  ]", 22)
		Style.label(stack, "Preview equipment" if title == "WEAPON" else "No items collected", 14)
	show_stats(false)
func clear_content(title: String) -> void:
	heading.text = title
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
func show_stats(secondary: bool) -> void:
	clear_content("Stats / " + ("Secondary" if secondary else "Primary"))
	var rows := ["HP Regeneration|0", "Life Steal|0%", "Critical Chance|5%", "Armor|0", "Dodge|0%", "Luck|0", "Harvesting|0"] if secondary else ["Character|" + GameData.selected_character, "Level|1", "Max HP|100", "Max MP|50", "Melee Damage|10", "Ranged Damage|10", "Attack Speed|100%", "Movement Speed|100%"]
	for entry in rows:
		var parts: PackedStringArray = entry.split("|")
		var row := HBoxContainer.new()
		content.add_child(row)
		var name_label := Style.label(row, parts[0], 19)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Style.label(row, parts[1], 19, Style.GOLD)
	Style.label(content, "Preview values / gameplay not connected", 14, Color("919a9f"))
func show_inventory() -> void:
	clear_content("Inventory & Equipment")
	Style.label(content, "Equipped: Pistol", 24, Style.GOLD)
	Style.label(content, "Ammunition: 10 / 10", 20)
	Style.label(content, "Your inventory is empty.", 20)
	Style.label(content, "Equipment and items are preview slots for now.", 16)
func show_settings() -> void:
	clear_content("Settings")
	Style.label(content, "Master volume", 20)
	var volume := HSlider.new()
	volume.max_value = 100
	volume.value = GameData.master_volume * 100
	volume.custom_minimum_size = Vector2(260, 35)
	content.add_child(volume)
	volume.value_changed.connect(func(value):
		GameData.master_volume = value / 100.0
		GameData.apply_settings()
		GameData.save_settings())
	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = GameData.fullscreen
	content.add_child(fullscreen)
	fullscreen.toggled.connect(func(value):
		GameData.fullscreen = value
		GameData.apply_settings()
		GameData.save_settings())
func show_controls() -> void:
	clear_content("Controls")
	Style.label(content, "ESC     Pause / Resume\nJ          Simulate hit (+1)\nK         Simulate kill (+3)\nR         Reset combo", 22)
	Style.label(content, "3 points per rank / 4 seconds before each drop", 16, Style.GOLD)
func toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		resume.grab_focus()
	else:
		get_viewport().gui_release_focus()
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		toggle_pause()
		get_viewport().set_input_as_handled()
func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
