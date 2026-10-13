extends Control
const Style = preload("res://scripts/ui_style.gd")
var stage_buttons: Dictionary = {}
var background: Control
func _ready() -> void:
	background = preload("res://scripts/home_background.gd").new()
	background.name = "StagePreview"
	background.auto_cycle = false
	background.initial_stage = maxi(GameData.STAGES.find(GameData.selected_stage),0)
	background.transition_duration = 0.25
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.03,0.04,0.34)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(1020,510)
	stack.add_theme_constant_override("separation",18)
	center.add_child(stack)
	var overline := Style.caption(stack,"01  /  SELECT YOUR DESTINATION",14,Style.GOLD)
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var heading := Style.label(stack,"CHOOSE YOUR STAGE",42)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := Style.caption(stack,"Hover to explore. Choose where your legend begins.",18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation",22)
	stack.add_child(cards)
	var details := {
		"grassland":["GRASSLAND","NORMAL MODE","Rolling hills. Forest paths.\nAncient ruins under open skies.","15:00  /  GOLEM ENCOUNTER",Color("8db894")],
		"desert":["DESERT","NORMAL MODE","Golden dunes. Sandstone gates.\nAn oasis beyond the horde.","15:00  /  GOLEM ENCOUNTER",Color("dfbc79")],
		"practice":["PRACTICE","SANDBOX","Build freely. Test every weapon.\nSpawn enemies on your terms.","U  /  OPEN PRACTICE TOOLS",Color("91baca")]
	}
	for stage in GameData.STAGES:
		var id: String = stage
		var info: Array = details[id]
		var accent: Color = info[4]
		var button := Style.button(cards,"",select_stage.bind(id))
		button.name = id.capitalize()+"Button"
		button.custom_minimum_size = Vector2(320,320)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal",Style.box(Color(0.07,0.09,0.11,0.96),accent))
		button.add_theme_stylebox_override("hover",Style.box(Color("253439"),accent))
		var content := Style.card_stack(button)
		Style.caption(content,"%02d  /  %s" % [GameData.STAGES.find(id)+1,info[1]],13,accent)
		Style.rule(content,accent)
		Style.caption(content,info[0],28,Style.PAPER)
		var description := Style.caption(content,info[2],17)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		Style.caption(content,info[3],12,accent)
		Style.caption(content,"SELECT STAGE  →",16,Style.PAPER)
		button.mouse_entered.connect(_preview_stage.bind(id))
		button.focus_entered.connect(_preview_stage.bind(id))
		stage_buttons[id] = button
	var back := Style.button(stack,"BACK",func(): SceneTransition.change_scene("res://scenes/main_menu.tscn"))
	back.custom_minimum_size.y = 46
func select_stage(stage: String) -> void:
	if stage not in GameData.STAGES: return
	GameData.selected_stage = stage
	SceneTransition.change_scene("res://scenes/character_select.tscn")
func _preview_stage(stage: String) -> void:
	var index := GameData.STAGES.find(stage)
	if index >= 0 and background.selected != index: background.select_world(index)
