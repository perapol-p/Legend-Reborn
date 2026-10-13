extends Control
const Style = preload("res://scripts/ui_style.gd")
const Portraits = preload("res://scripts/character_widgets.gd")
func _ready() -> void:
 var background = preload("res://scripts/home_background.gd").new()
 background.name = "SelectedStageBackground"
 background.auto_cycle = false
 background.initial_stage = maxi(GameData.STAGES.find(GameData.selected_stage),0)
 add_child(background)
 move_child(background,0)
 $BG.color = Color(0.02,0.03,0.04,0.28)
 $BG.mouse_filter = Control.MOUSE_FILTER_IGNORE
 GameData.selected_character = GameData.normalize_character(GameData.selected_character)
 var character: String = GameData.selected_character
 $Center/Panel.add_theme_stylebox_override("panel",Style.box(Color("1b222b"),Style.GOLD,14))
 $Center/Panel/VBox/Title.text = character.to_upper()
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",10)
 $Center/Panel/VBox/Body/Portrait.add_child(stack)
 Portraits.portrait(stack,character,Vector2(0,330))
 var name_label := Style.label(stack,character,24,Style.GOLD)
 name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var catalog = preload("res://scripts/item_catalog.gd").new()
 var role: String = {"Saber":"Swordsman","Archer":"Archer","Wizard god":"Mage"}[character]
 $Center/Panel/VBox/Body/Detail.text = "CHARACTER DETAIL\n\nName: %s\nRole: %s\nBase weapon: %s\n\nStage: %s\nMode: %s" % [character,role,catalog.weapon_name(character),GameData.STAGE_NAMES[GameData.selected_stage],"Sandbox" if GameData.selected_stage=="practice" else "Normal Mode"]
 $Center/Panel/VBox/Body/Detail.add_theme_font_size_override("font_size",22)
 $Center/Panel/VBox/Buttons/Back.pressed.connect(func(): SceneTransition.change_scene("res://scenes/character_select.tscn"))
 $Center/Panel/VBox/Buttons/Go.pressed.connect(func(): SceneTransition.change_scene("res://scenes/game_placeholder.tscn"))
