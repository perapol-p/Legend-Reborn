extends Control
const Style = preload("res://scripts/ui_style.gd")
const SettingsPanel = preload("res://scripts/settings_panel.gd")
@export var initial_page := "General"
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := ColorRect.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("10171d")
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(1020,620)
	var border := Style.box(Color("111b23"),Style.GOLD)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: border.set_content_margin(side,26)
	frame.add_theme_stylebox_override("panel",border)
	center.add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	frame.add_child(column)
	Style.caption(column,"LEGEND REBORN  /  PREFERENCES",13,Style.GOLD)
	Style.label(column,"SETTINGS",38)
	Style.rule(column)
	var panel := SettingsPanel.new()
	panel.page = initial_page
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel)
	Style.button(column,"BACK",func(): SceneTransition.change_scene("res://scenes/main_menu.tscn"))
