extends RefCounted
const INK = Color("171b20")
const GOLD = Color("c6ad72")
const PAPER = Color("eee6d1")
static func box(color: Color, border: Color = Color.TRANSPARENT, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
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
	parent.add_child(n)
	n.pressed.connect(action)
	return n
static func bar(parent: Node, color: Color, value: float, height: float = 16) -> ProgressBar:
	var n := ProgressBar.new()
	n.custom_minimum_size.y = height
	n.show_percentage = false
	n.value = value
	n.add_theme_stylebox_override("background", box(Color("24282d"), Color.TRANSPARENT, 6))
	n.add_theme_stylebox_override("fill", box(color, Color.TRANSPARENT, 6))
	parent.add_child(n)
	return n
