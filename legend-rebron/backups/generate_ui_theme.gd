extends SceneTree
func _initialize():
 var theme := Theme.new()
 var style = preload("res://scripts/ui_style.gd")
 theme.default_font_size = 18
 theme.default_font = style.FONT
 for key in ["normal_font","bold_font","italics_font","bold_italics_font","mono_font"]:
  theme.set_font(key,"RichTextLabel",style.FONT)
 for type in ["Button","OptionButton","CheckButton","CheckBox","MenuButton"]:
  theme.set_stylebox("normal",type,style.box(Color("25292e"),Color("4c473b")))
  theme.set_stylebox("hover",type,style.box(Color("474031"),style.GOLD))
  theme.set_stylebox("pressed",type,style.box(Color("754128"),style.GOLD))
  theme.set_stylebox("hover_pressed",type,style.box(Color("754128"),style.GOLD))
  theme.set_stylebox("disabled",type,style.box(Color("1b2025"),Color("667078")))
  theme.set_stylebox("focus",type,style.box(Color(0.4,0.35,0.18,0.22),style.GOLD))
  theme.set_color("font_color",type,style.PAPER)
  theme.set_color("font_hover_color",type,Color.WHITE)
  theme.set_color("font_pressed_color",type,style.PAPER)
  theme.set_color("font_disabled_color",type,Color("8b969e"))
 for type in ["Panel","PanelContainer","PopupPanel","PopupMenu","AcceptDialog","Window"]:
  theme.set_stylebox("panel",type,style.box(style.INK,style.GOLD))
 for type in ["LineEdit","TextEdit"]:
  theme.set_stylebox("normal",type,style.box(Color("171b20"),Color("46545c")))
  theme.set_stylebox("focus",type,style.box(Color("25292e"),style.GOLD))
  theme.set_stylebox("read_only",type,style.box(Color("171b20")))
 theme.set_color("font_color","Label",style.PAPER)
 assert(ResourceSaver.save(theme,"res://assets/ui/legend_theme.tres") == OK)
 print("UI texture theme generated")
 quit()
