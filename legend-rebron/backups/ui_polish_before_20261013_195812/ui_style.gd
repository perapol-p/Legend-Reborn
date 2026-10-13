extends RefCounted
const INK = Color("171b20")
const GOLD = Color("c6ad72")
const PAPER = Color("eee6d1")
const FRAME = preload("res://assets/ui/TextBox-export.png")
static func box(color: Color, border: Color = Color.TRANSPARENT, _radius: int = 8) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = FRAME
	# Remove the source's outer transparent padding before nine-slice stretching.
	s.region_rect = Rect2(20,22,474,162)
	s.set_texture_margin_all(12)
	s.modulate_color = color.lightened(0.22).lerp(Color(border, color.a),0.16 if border.a > 0 else 0.0)
	s.modulate_color.a = color.a
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
# Meter fills stay solid so their displayed length remains exact.
static func meter_box(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(4)
	return s
static func label(parent: Node, text: String, size: int = 20, color: Color = PAPER) -> Label:
	var n := Label.new()
	n.text = text
	n.add_theme_font_size_override("font_size", size)
	n.add_theme_color_override("font_color", color)
	parent.add_child(n)
	return n
static func button(parent: Node, text: String, action: Callable) -> Button:
	var n := Button.new()
	n.text = text
	n.custom_minimum_size.y = 42
	n.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	n.add_theme_color_override("font_color", PAPER)
	n.add_theme_stylebox_override("normal", box(Color("25292e"), Color("4c473b")))
	n.add_theme_stylebox_override("hover", box(Color("474031"), GOLD))
	n.add_theme_stylebox_override("pressed", box(Color("754128"), GOLD))
	n.add_theme_stylebox_override("disabled",box(Color("1b2025"),Color("667078")))
	n.add_theme_stylebox_override("focus",box(Color(0.4,0.35,0.18,0.22),GOLD))
	n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(n)
	n.pressed.connect(action)
	return n
static func bar(parent: Node, color: Color, value: float, height: float = 16) -> ProgressBar:
	var n := ProgressBar.new()
	n.custom_minimum_size.y = height
	n.show_percentage = false
	n.value = value
	n.add_theme_stylebox_override("background", meter_box(Color("24282d")))
	n.add_theme_stylebox_override("fill", meter_box(color))
	parent.add_child(n)
	return n
