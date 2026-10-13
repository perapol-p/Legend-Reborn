extends Control
const Style = preload("res://scripts/ui_style.gd")
var stage_buttons: Dictionary = {}
func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("10171c")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(1020,440)
	stack.add_theme_constant_override("separation",24)
	center.add_child(stack)
	var heading := Style.label(stack,"CHOOSE YOUR STAGE",38,Style.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := Style.label(stack,"Survive the normal stages or test your build in Practice.",18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation",20)
	stack.add_child(cards)
	var descriptions := {
		"grassland":"GRASSLAND\nNORMAL MODE\n\nRolling hills and forest\nAncient stone ruins\nBoss arrives at 15:00",
		"desert":"DESERT\nNORMAL MODE\n\nSand dunes and cacti\nOasis and sandstone gates\nBoss arrives at 15:00",
		"practice":"PRACTICE\nSANDBOX\n\nGrid arena, ramps and pyramids\nU tools / Manual enemies"
	}
	for stage in GameData.STAGES:
		var id: String = stage
		var button := Style.button(cards,descriptions[id],func(): select_stage(id))
		button.name = id.capitalize()+"Button"
		button.custom_minimum_size = Vector2(320,260)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage_buttons[id] = button
		button.add_theme_font_size_override("font_size",20)
	Style.button(stack,"BACK",func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
func select_stage(stage: String) -> void:
	if stage not in GameData.STAGES:
		return
	GameData.selected_stage = stage
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

