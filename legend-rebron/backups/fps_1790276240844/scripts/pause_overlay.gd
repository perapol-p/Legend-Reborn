extends Control
const Style = preload("res://scripts/ui_style.gd")
const ItemWidgets = preload("res://scripts/item_widgets.gd")
var run: Node
var current_page := "primary"
var weapon_summary: Label
var item_summary: Label
var item_flow: HFlowContainer
var content: VBoxContainer
var heading: Label
var resume: Button
func _ready() -> void:
	hide()
	var shade := ColorRect.new()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.035, 0.04, 0.97)
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
	var weapon_slot := PanelContainer.new()
	weapon_slot.custom_minimum_size.x = 365
	weapon_slot.add_theme_stylebox_override("panel", Style.box(Color("25292e"), Style.GOLD))
	equipment.add_child(weapon_slot)
	var weapon_stack := VBoxContainer.new()
	weapon_slot.add_child(weapon_stack)
	Style.label(weapon_stack, "BASE WEAPON", 16, Style.GOLD)
	weapon_summary = Style.label(weapon_stack, "Not assigned", 22)
	Style.label(weapon_stack, "Sword / Katana / Gun / Bow / Spellbook", 14)
	var item_slot := PanelContainer.new()
	item_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_slot.add_theme_stylebox_override("panel", Style.box(Color("25292e"), Style.GOLD))
	equipment.add_child(item_slot)
	var item_stack := VBoxContainer.new()
	item_slot.add_child(item_stack)
	item_summary = Style.label(item_stack, "ITEMS / 0", 16, Style.GOLD)
	var item_scroll := ScrollContainer.new()
	item_scroll.custom_minimum_size.y = 70
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_stack.add_child(item_scroll)
	item_flow = HFlowContainer.new()
	item_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_flow.add_theme_constant_override("h_separation", 8)
	item_flow.add_theme_constant_override("v_separation", 8)
	item_scroll.add_child(item_flow)
	show_stats(false)
func bind_run(model: Node) -> void:
	run = model
	run.changed.connect(refresh_run)
	refresh_run()
func refresh_run() -> void:
	weapon_summary.text = run.catalog.weapon_name(run.character_name)
	item_summary.text = "ITEMS / %d" % run.owned_ids.size()
	for child in item_flow.get_children():
		item_flow.remove_child(child)
		child.queue_free()
	fill_inventory(item_flow)
	match current_page:
		"primary": show_stats(false)
		"secondary": show_stats(true)
		"inventory": show_inventory()
func fill_inventory(parent: Node) -> void:
	if run == null or run.owned_ids.is_empty():
		Style.label(parent, "No items collected", 16)
		return
	for id in run.owned_ids:
		ItemWidgets.badge(parent, run.catalog, run.catalog.item_for(id))

func clear_content(title: String) -> void:
	heading.text = title
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
func show_stats(secondary: bool) -> void:
	current_page = "secondary" if secondary else "primary"
	clear_content("Stats / " + ("Secondary" if secondary else "Primary"))
	if run == null:
		return
	var values: Dictionary = run.stats()
	var rows: Array = [
		["Character", run.character_name],
		["Level", str(run.level)],
		["Max HP", run.catalog.format_number(float(values["max_hp"]))],
		["Max MP", run.catalog.format_number(float(values["max_mp"]))],
		["ATK", run.catalog.format_number(float(values["attack"]))],
		["Speed", run.catalog.format_number(float(values["speed"])) + " pts"],
		["Base weapon", run.catalog.weapon_name(run.character_name)]
	]
	if secondary:
		rows = [
			["Crit chance", run.catalog.format_number(float(values["crit_chance"])) + "%"],
			["Crit damage", run.catalog.format_number(float(values["crit_damage"])) + "%"],
			["Luck", run.catalog.format_number(float(values["luck"])) + "%"]
		]
	for entry in rows:
		var row := HBoxContainer.new()
		content.add_child(row)
		var name_label := Style.label(row, entry[0], 19)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Style.label(row, entry[1], 19, Style.GOLD)
func show_inventory() -> void:
	current_page = "inventory"
	clear_content("Inventory")
	if run == null:
		return
	Style.label(content, "%d / %d items collected" % [run.owned_ids.size(), run.catalog.items.size()], 22, Style.GOLD)
	Style.label(content, "Bonuses apply immediately. Hover an item for details.", 16)
	var inventory := HFlowContainer.new()
	inventory.add_theme_constant_override("h_separation", 10)
	inventory.add_theme_constant_override("v_separation", 10)
	content.add_child(inventory)
	fill_inventory(inventory)
func show_settings() -> void:
	current_page = "settings"
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
	current_page = "controls"
	clear_content("Controls")
	Style.label(content, "ESC     Pause / Resume\nJ          Simulate hit (+1)\nK         Simulate kill (+3)\nR         Reset combo\nL          Test level up\n1 / 2 / 3    Choose reward", 22)
	Style.label(content, "3 points per rank / 4 seconds before each drop", 16, Style.GOLD)
func toggle_pause() -> void:
	if run != null and not run.offers.is_empty():
		return
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
