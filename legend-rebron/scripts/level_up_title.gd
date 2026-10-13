extends Control
var clock := 0.0
var lettering: Control
var glow: Label
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 custom_minimum_size = Vector2(0,82)
 lettering = Control.new()
 lettering.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(lettering)
 lettering.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 glow = _label(Color(1,0.72,0.23,0.7),Color(1,0.65,0.12,0.32),16)
 _label(Color("#fff2b3"),Color("#52361a"),2)
func _label(color: Color, outline: Color, width: int) -> Label:
 var label := Label.new()
 label.text = "LEVEL UP!"
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",58)
 label.add_theme_color_override("font_color",color)
 label.add_theme_color_override("font_outline_color",outline)
 label.add_theme_constant_override("outline_size",width)
 lettering.add_child(label)
 label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 return label
func restart() -> void:
 clock = 0.0
func _process(delta: float) -> void:
 if not is_visible_in_tree(): return
 clock += delta
 lettering.pivot_offset = size*0.5
 lettering.scale = Vector2.ONE*(1.0+0.025*sin(clock*5.0))
 lettering.rotation = deg_to_rad(0.9)*sin(clock*3.3)
 glow.modulate.a = 0.7+0.25*sin(clock*5.0)
