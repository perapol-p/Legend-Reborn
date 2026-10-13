extends Control
const Style = preload("res://scripts/ui_style.gd")
const SettingsPanel = preload("res://scripts/settings_panel.gd")
@export var initial_page := "General"
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := ColorRect.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("10141b")
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	var column := VBoxContainer.new()
	margin.add_child(column)
	Style.label(column, "SETTINGS", 36, Style.GOLD)
	var panel := SettingsPanel.new()
	panel.page = initial_page
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel)
	Style.button(column, "Back", func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
