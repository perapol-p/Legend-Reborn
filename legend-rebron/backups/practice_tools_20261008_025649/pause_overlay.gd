extends Control
const Style = preload("res://scripts/ui_style.gd")
signal pause_changed
const SettingsPanel = preload("res://scripts/settings_panel.gd")
const ItemWidgets = preload("res://scripts/item_widgets.gd")
var run: Node
var current_page := "stats"
var weapon_summary: Label
var item_summary: Label
var item_flow: HFlowContainer
var content: VBoxContainer
var heading: Label
var resume: Button
var menu: VBoxContainer
var menu_center: CenterContainer
var stats_panel: PanelContainer
var equipment: HBoxContainer
var shade: ColorRect
var background_panels: Array[PanelContainer] = []
var overlay_mode := "menu"
func _ready() -> void:
	hide()
	shade = ColorRect.new()
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
	menu_center = CenterContainer.new()
	menu_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(menu_center)
	menu = VBoxContainer.new()
	menu.custom_minimum_size.x = 365
	menu.add_theme_constant_override("separation", 8)
	menu_center.add_child(menu)
	Style.label(menu, "LEGEND REBORN", 22, Style.GOLD)
	Style.label(menu, "Paused", 58)
	resume = Style.button(menu, "Resume", toggle_pause)
	Style.button(menu, "Settings", show_settings)
	Style.button(menu, "Return to Main Menu", return_to_menu)
	Style.button(menu, "Quit to Desktop", func(): get_tree().quit())
	var panel := PanelContainer.new()
	stats_panel = panel
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", Style.box(Color("202429"), Color("57503e")))
	body.add_child(panel)
	var right := VBoxContainer.new()
	panel.add_child(right)
	heading = Style.label(right, "Stats", 30)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	equipment = HBoxContainer.new()
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
	background_panels = [stats_panel, weapon_slot, item_slot]
	GameData.settings_changed.connect(refresh_opacity)
	show_stats()
	show_menu()
func bind_run(model: Node) -> void:
	run = model
	run.changed.connect(refresh_run)
	refresh_run()
func refresh_run() -> void:
	weapon_summary.text = run.weapon_name()
	item_summary.text = "ITEMS / %d  (%d types)" % [run.total_items(), run.owned_ids.size()]
	for child in item_flow.get_children():
		item_flow.remove_child(child)
		child.queue_free()
	fill_inventory(item_flow)
	if overlay_mode == "menu" and not stats_panel.visible:
		return
	match current_page:
		"stats": show_stats()
		"inventory": show_inventory()
func fill_inventory(parent: Node) -> void:
	if run == null or run.owned_ids.is_empty():
		Style.label(parent, "No items collected", 16)
		return
	for id in run.owned_ids:
		ItemWidgets.badge(parent, run.catalog, run.catalog.item_for(id), run.stack_count(id))

func clear_content(title: String) -> void:
	heading.text = title
	stats_panel.show()
	menu_center.size_flags_horizontal = Control.SIZE_FILL
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
func show_stats() -> void:
	current_page = "stats"
	clear_content("Stats")
	if run == null:
		return
	var values: Dictionary = run.stats()
	var rows: Array = [
		["Character", run.character_name],
		["Level", str(run.level)],
		["Max HP", run.catalog.format_number(float(values["max_hp"]))],
		["ATK", run.catalog.format_number(float(values["attack"]))],
		["Speed", run.catalog.format_number(float(values["speed"])) + " pts"],
		["Base weapon", run.weapon_name()],
		["Crit chance", run.catalog.format_number(float(values["crit_chance"] )) + "%"],
		["Crit damage", run.catalog.format_number(float(values["crit_damage"] )) + "%"],
		["Luck", run.catalog.format_number(float(values["luck"] )) + "%"]
	]
	for entry in rows:
		var row := HBoxContainer.new()
		content.add_child(row)
		var name_label := Style.label(row, entry[0], 19)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Style.label(row, entry[1], 19, Style.GOLD)
func show_inventory() -> void:
	equipment.show()
	current_page = "inventory"
	clear_content("Inventory")
	if run == null:
		return
	Style.label(content, "%d items collected / %d types" % [run.total_items(), run.owned_ids.size()], 22, Style.GOLD)
	Style.label(content, "Each stack adds its bonus. Hover an item for details.", 16)
	var inventory := HFlowContainer.new()
	inventory.add_theme_constant_override("h_separation", 10)
	inventory.add_theme_constant_override("v_separation", 10)
	content.add_child(inventory)
	fill_inventory(inventory)
func show_settings() -> void:
	current_page = "settings"
	clear_content("Settings")
	var settings := SettingsPanel.new()
	content.add_child(settings)
func show_controls() -> void:
	current_page = "controls"
	clear_content("Keyboard")
	var settings := SettingsPanel.new()
	settings.page = "Keyboard"
	content.add_child(settings)
func show_menu() -> void:
	overlay_mode = "menu"
	menu.show()
	menu_center.show()
	menu_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_panel.hide()
	equipment.hide()
	refresh_opacity()
	resume.grab_focus()
func toggle_stats() -> void:
	if run != null and not run.offers.is_empty():
		return
	if visible:
		return
	overlay_mode = "stats"
	menu.hide()
	menu_center.hide()
	equipment.show()
	show_stats()
	visible = true
	get_tree().paused = true
	get_viewport().gui_release_focus()
	refresh_opacity()
	pause_changed.emit()
func refresh_opacity() -> void:
	var opacity: float = GameData.tab_ui_opacity if overlay_mode == "stats" else 1.0
	shade.color = Color(0.025, 0.035, 0.04, 0.35 * opacity if overlay_mode == "stats" else 0.97)
	for panel in background_panels:
		var background := panel.get_theme_stylebox("panel") as StyleBoxFlat
		background.bg_color.a = opacity
		background.border_color.a = opacity
func _close_overlay() -> void:
	hide()
	get_tree().paused = false
	get_viewport().gui_release_focus()
	pause_changed.emit()
func toggle_pause() -> void:
	if run != null and not run.offers.is_empty():
		return
	if visible and overlay_mode == "stats":
		show_menu()
	elif visible:
		_close_overlay()
	else:
		show_menu()
		show()
		get_tree().paused = true
		pause_changed.emit()
func _input(event: InputEvent) -> void:
	if GameData.command_console_active:
		return
	if GameData.rebinding_active:
		return
	if event.is_action_released("toggle_cursor"):
		if visible and overlay_mode == "stats":
			_close_overlay()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_cursor") and not event.is_echo():
		toggle_stats()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		toggle_pause()
		get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_node_ready() and visible and overlay_mode == "stats":
		show_menu()
func return_to_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

