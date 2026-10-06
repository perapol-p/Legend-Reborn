extends ColorRect
const Style = preload("res://scripts/ui_style.gd")
signal retry_requested
signal main_menu_requested
var summary: Dictionary
var won := false
var retry_button: Button
var main_menu_button: Button
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.025, 0.035, 0.045, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(940, 590)
	panel.add_theme_stylebox_override("panel", Style.box(Style.INK, Style.GOLD if won else Color("bc4a45")))
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)
	var title := Style.label(stack, "VICTORY" if won else "GAME OVER", 42, Style.GOLD if won else Color("ed7771"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var seconds := int(summary["elapsed_seconds"])
	var headline := Style.label(stack, "SURVIVED %02d:%02d  /  MONSTERS KILLED %d" % [seconds / 60, seconds % 60, summary["monsters_killed"]], 22)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 32)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(body)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 400
	body.add_child(details)
	Style.label(details, "CHARACTER / " + str(summary["character"]), 24, Style.GOLD)
	Style.label(details, "LEVEL %d  /  %s LV %d" % [summary["level"], summary["weapon_name"], summary["weapon_level"]], 20)
	Style.label(details, "FINAL STATS", 20, Style.GOLD)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	details.add_child(grid)
	var stats: Dictionary = summary["stats"]
	for key in stats:
		Style.label(grid, str(preload("res://scripts/item_catalog.gd").STAT_NAMES.get(key, key)), 18)
		var suffix := "%" if key in ["luck", "crit_chance", "crit_damage"] else ""
		Style.label(grid, preload("res://scripts/item_catalog.gd").format_number(float(stats[key])) + suffix, 18)
	Style.label(details, "HP remaining: " + preload("res://scripts/item_catalog.gd").format_number(float(summary["health"])), 18)
	var inventory := VBoxContainer.new()
	inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(inventory)
	Style.label(inventory, "ITEMS / %d TOTAL" % summary["item_total"], 20, Style.GOLD)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 330
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory.add_child(scroll)
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation", 8)
	scroll.add_child(items)
	if summary["items"].is_empty():
		Style.label(items, "No items collected", 18)
	for item in summary["items"]:
		Style.label(items, "%s  x%d" % [item["name"], item["count"]], 18, item["color"])
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	stack.add_child(buttons)
	retry_button = Style.button(buttons, "RETRY", func(): retry_requested.emit())
	retry_button.name = "RetryButton"
	retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_menu_button = Style.button(buttons, "MAIN MENU", func(): main_menu_requested.emit())
	main_menu_button.name = "MainMenuButton"
	main_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_button.grab_focus()
