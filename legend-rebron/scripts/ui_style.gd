extends RefCounted
const FONT = preload("res://assets/ui/fonts/Font.ttf")
const INK = Color("171b20")
const GOLD = Color("dfbc79")
const MUTED = Color("a9b5ba")
const PAPER = Color("eee6d1")
const FRAME = preload("res://assets/ui/TextBox2.png")
const INSET = preload("res://assets/ui/TextBox3.png")
const HERO = preload("res://assets/ui/TextBox-export.png")
const GAME_LOGO = preload("res://assets/ui/BigGameLogo.png")
static var cropped_logo: AtlasTexture
static func box(color: Color, border: Color = Color.TRANSPARENT, _radius: int = 8) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = FRAME
	# Remove the source's outer transparent padding before nine-slice stretching.
	s.region_rect = Rect2(0,0,51,22)
	s.set_texture_margin_all(4)
	s.modulate_color = color.lightened(0.12).lerp(Color(border, color.a),0.24 if border.a > 0 else 0.0)
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
	n.custom_minimum_size.y = 48
	n.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	n.add_theme_color_override("font_color", PAPER)
	n.add_theme_stylebox_override("normal", box(Color("25292e"), Color("4c473b")))
	n.add_theme_stylebox_override("hover", box(Color("474031"), GOLD))
	n.add_theme_stylebox_override("pressed", box(Color("754128"), GOLD))
	n.add_theme_stylebox_override("disabled",box(Color("1b2025"),Color("667078")))
	n.add_theme_stylebox_override("focus",box(Color(0.4,0.35,0.18,0.22),GOLD))
	n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	n.add_theme_font_size_override("font_size",18)
	n.add_theme_color_override("font_hover_color",Color.WHITE)
	n.add_theme_color_override("font_disabled_color",MUTED)
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

static func inset(color: Color = INK, accent: Color = Color.TRANSPARENT) -> StyleBoxTexture:
	var s := box(color,accent)
	s.texture = INSET
	s.region_rect = Rect2(0,0,49,21)
	s.set_texture_margin_all(2)
	return s
static func primary(button: Button) -> void:
	var normal := box(Color("343224"),GOLD)

	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",box(Color("55503b"),GOLD))
	button.add_theme_stylebox_override("pressed",box(Color("29251c"),GOLD))
	button.add_theme_color_override("font_color",Color("ffe4ad"))
	button.add_theme_font_size_override("font_size",20)
	button.custom_minimum_size.y = 56
static func rule(parent: Node, color: Color = GOLD) -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size.y = 2
	line.color = Color(color,0.65)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	return line
static func card_stack(button: Button, padding: int = 22) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,padding)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation",12)
	margin.add_child(stack)
	return stack
static func caption(parent: Node, text: String, size: int = 14, color: Color = MUTED) -> Label:
	var n := label(parent,text,size,color)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

static func logo_texture() -> AtlasTexture:
	if cropped_logo == null:
		cropped_logo = AtlasTexture.new()
		cropped_logo.atlas = GAME_LOGO
		cropped_logo.region = Rect2(GAME_LOGO.get_image().get_used_rect()).grow(8.0)
	return cropped_logo
static func game_logo(parent: Node, minimum: Vector2) -> TextureRect:
	var logo := TextureRect.new()
	logo.name = "GameLogo"
	logo.texture = logo_texture()
	logo.custom_minimum_size = minimum
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(logo)
	return logo
