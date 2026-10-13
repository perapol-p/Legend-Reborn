extends Control
const Style = preload("res://scripts/ui_style.gd")
const Portraits = preload("res://scripts/character_widgets.gd")
var character_buttons: Dictionary = {}
var status_labels: Dictionary = {}
func _ready() -> void:
 var background = preload("res://scripts/home_background.gd").new()
 background.name = "SelectedStageBackground"
 background.auto_cycle = false
 background.initial_stage = maxi(GameData.STAGES.find(GameData.selected_stage),0)
 add_child(background)
 move_child(background,0)
 $BG.color = Color(0.02,0.03,0.04,0.28)
 $BG.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for child in $Center/VBox/Cards.get_children():
  $Center/VBox/Cards.remove_child(child)
  child.queue_free()
 var catalog = preload("res://scripts/item_catalog.gd").new()
 for character in GameData.CHARACTERS:
  var button := Style.button($Center/VBox/Cards,"",_select.bind(character))
  button.name = "Character_"+character.replace(" ","_")
  button.custom_minimum_size = Vector2(310,435)
  var margin := MarginContainer.new()
  margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
  button.add_child(margin)
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
  var stack := VBoxContainer.new()
  stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
  stack.add_theme_constant_override("separation",10)
  margin.add_child(stack)
  var role: String = {"Saber":"MELEE / SWORDSMAN","Archer":"RANGED / ARCHER","Wizard god":"MAGIC / MAGE"}[character]
  Style.caption(stack,role,12,Style.GOLD)
  Portraits.portrait(stack,character,Vector2(0,255))
  var name_label := Style.label(stack,character,26)
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var weapon_label := Style.label(stack,catalog.weapon_name(character).to_upper(),16,Style.GOLD)
  weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var status := Style.label(stack,"",14)
  status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  status.mouse_filter = Control.MOUSE_FILTER_IGNORE
  character_buttons[character] = button
  status_labels[character] = status
 var subtitle := Style.caption($Center/VBox,"02  /  CHOOSE YOUR CLASS  /  "+GameData.STAGE_NAMES[GameData.selected_stage].to_upper(),14,Style.GOLD)
 subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 $Center/VBox.move_child(subtitle,1)
 $Center/VBox.add_theme_constant_override("separation",18)
 $Center/VBox/Back.text = "BACK"
 $Center/VBox/Back.pressed.connect(func(): SceneTransition.change_scene("res://scenes/stage_select.tscn"))
 GameData.characters_changed.connect(_refresh_characters)
 _refresh_characters()
func _refresh_characters() -> void:
 for character in GameData.CHARACTERS:
  var unlocked := GameData.is_character_unlocked(character)
  character_buttons[character].disabled = not unlocked
  character_buttons[character].modulate = Color.WHITE if unlocked else Color(0.65,0.65,0.65)
  status_labels[character].text = "SELECT CHARACTER  →" if unlocked else ("LOCKED / WIN 1 RUN" if character == "Archer" else "LOCKED / UNLOCK IN PRACTICE")
func _select(character: String) -> void:
 if not GameData.is_character_unlocked(character): return
 GameData.selected_character = character
 SceneTransition.change_scene("res://scenes/character_detail.tscn")
