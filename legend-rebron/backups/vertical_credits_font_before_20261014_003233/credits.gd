extends Control
const Style = preload("res://scripts/ui_style.gd")
const TEAM = [
 {"name":"Perapol Promsorn","id":"683380308-7","role":"3D Model / Animator"},
 {"name":"Naponphat Ramanggoon","id":"683380072-0","role":"Script / Coding"},
 {"name":"Chutipon Kaewsanga","id":"683380289-5","role":"2D Artist / UI Designer"}
]
func _ready() -> void:
 var stack := $Center/Panel/VBox
 stack.add_theme_constant_override("separation",18)
 Style.game_logo(stack,Vector2(0,104))
 var title := Style.label(stack,"CREDITS",32,Style.PAPER)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var cards := HBoxContainer.new()
 cards.name = "Team"
 cards.add_theme_constant_override("separation",18)
 stack.add_child(cards)
 for member in TEAM:
  var panel := PanelContainer.new()
  panel.custom_minimum_size = Vector2(296,250)
  panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  panel.add_theme_stylebox_override("panel",Style.box(Color("171f26"),Style.GOLD))
  cards.add_child(panel)
  var content := VBoxContainer.new()
  content.add_theme_constant_override("separation",16)
  panel.add_child(content)
  var role := Style.label(content,member["role"],18,Style.GOLD)
  role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  Style.rule(content,Style.GOLD)
  var spacer := Control.new()
  spacer.custom_minimum_size.y = 14
  content.add_child(spacer)
  var name_label := Style.label(content,member["name"],24)
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
  var id := Style.label(content,member["id"],17,Style.MUTED)
  id.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var back := Style.button(stack,"BACK",func(): SceneTransition.change_scene("res://scenes/main_menu.tscn"))
 back.name = "Back"
