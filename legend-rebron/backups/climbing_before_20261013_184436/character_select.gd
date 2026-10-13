extends Control
const Style = preload("res://scripts/ui_style.gd")
const Portraits = preload("res://scripts/character_widgets.gd")
var character_buttons: Dictionary = {}
var status_labels: Dictionary = {}
func _ready() -> void:
 for child in $Center/VBox/Cards.get_children():
  $Center/VBox/Cards.remove_child(child)
  child.queue_free()
 var catalog = preload("res://scripts/item_catalog.gd").new()
 for character in GameData.CHARACTERS:
  var button := Style.button($Center/VBox/Cards,"",_select.bind(character))
  button.name = "Character_"+character.replace(" ","_")
  button.custom_minimum_size = Vector2(300,390)
  var margin := MarginContainer.new()
  margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
  button.add_child(margin)
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,14)
  var stack := VBoxContainer.new()
  stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
  stack.add_theme_constant_override("separation",10)
  margin.add_child(stack)
  Portraits.portrait(stack,character,Vector2(0,230))
  var name_label := Style.label(stack,character,26)
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var weapon_label := Style.label(stack,catalog.weapon_name(character).to_upper(),16,Style.GOLD)
  weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var status := Style.label(stack,"",14)
  status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  status.mouse_filter = Control.MOUSE_FILTER_IGNORE
  character_buttons[character] = button
  status_labels[character] = status
 $Center/VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/stage_select.tscn"))
 GameData.characters_changed.connect(_refresh_characters)
 _refresh_characters()
func _refresh_characters() -> void:
 for character in GameData.CHARACTERS:
  var unlocked := GameData.is_character_unlocked(character)
  character_buttons[character].disabled = not unlocked
  character_buttons[character].modulate = Color.WHITE if unlocked else Color(0.65,0.65,0.65)
  status_labels[character].text = "AVAILABLE" if unlocked else ("LOCKED / WIN 1 RUN" if character == "Archer" else "LOCKED / UNLOCK IN PRACTICE")
func _select(character: String) -> void:
 if not GameData.is_character_unlocked(character): return
 GameData.selected_character = character
 get_tree().change_scene_to_file("res://scenes/character_detail.tscn")
