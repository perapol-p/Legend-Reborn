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
 $Center/Panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 var team := VBoxContainer.new()
 team.name = "Team"
 team.add_theme_constant_override("separation",22)
 stack.add_child(team)
 for member in TEAM:
  var entry := VBoxContainer.new()
  entry.add_theme_constant_override("separation",5)
  team.add_child(entry)
  var name_label := Style.label(entry,member["name"],26)
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var id := Style.label(entry,member["id"],17,Style.MUTED)
  id.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var role := Style.label(entry,member["role"],18,Style.GOLD)
  role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var back := Style.button(stack,"BACK",func(): SceneTransition.change_scene("res://scenes/main_menu.tscn"))
 back.name = "Back"
