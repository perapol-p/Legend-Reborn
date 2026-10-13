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
 $Center/Panel/VBox/Title.text = "YOUR LOADOUT"
 $Center/Panel/VBox/Title.add_theme_font_size_override("font_size",32)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",10)
 $Center/Panel/VBox/Body/Portrait.add_child(stack)
 Portraits.portrait(stack,character,Vector2(0,330))
 var name_label := Style.label(stack,character,24,Style.GOLD)
 name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var catalog = preload("res://scripts/item_catalog.gd").new()
 var role: String = {"Saber":"Swordsman","Archer":"Archer","Wizard god":"Mage"}[character]
 $Center/Panel/VBox/Body/Detail.bbcode_enabled = true
 $Center/Panel/VBox/Body/Detail.scroll_active = false
 var weapon: String = catalog.weapon_name(character)
 var stage: String = GameData.STAGE_NAMES[GameData.selected_stage]
 var mode: String = "SANDBOX" if GameData.selected_stage == "practice" else "NORMAL MODE"
 $Center/Panel/VBox/Body/Detail.text = "[color=#dfbc79][font_size=13]03  /  READY FOR THE RUN[/font_size][/color]\n\n[font_size=42]%s[/font_size]\n[color=#a9b5ba][font_size=22]%s[/font_size][/color]\n\n[color=#dfbc79][font_size=13]BASE WEAPON[/font_size][/color]\n[font_size=26]%s[/font_size]\n\n[color=#dfbc79][font_size=13]DESTINATION[/font_size][/color]\n[font_size=24]%s[/font_size]\n[color=#a9b5ba][font_size=15]%s[/font_size][/color]" % [character,role,weapon,stage,mode]
 $Center/Panel/VBox/Body/Detail.add_theme_color_override("default_color",Style.PAPER)
 $Center/Panel/VBox/Buttons/Back.text = "BACK"
 $Center/Panel/VBox/Buttons/Go.text = "START RUN  →"
 Style.primary($Center/Panel/VBox/Buttons/Go)
 $Center/Panel/VBox/Buttons/Back.pressed.connect(func(): SceneTransition.change_scene("res://scenes/character_select.tscn"))
 $Center/Panel/VBox/Buttons/Go.pressed.connect(func(): SceneTransition.change_scene("res://scenes/game_placeholder.tscn"))
