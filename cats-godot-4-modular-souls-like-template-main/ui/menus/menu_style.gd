extends RefCounted
const GOLD = Color("d2be8c")
const LIGHT = Color("ede5d1")
const MUTED = Color("9b9a91")

static func serif() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	return font

static func label(text: String, size: int = 20, color: Color = LIGHT, classic: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if classic:
		node.add_theme_font_override("font", serif())
	return node

static func style(background: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = background
	result.border_color = border
	result.border_width_top = 1
	result.border_width_bottom = 1
	result.content_margin_left = 18
	result.content_margin_right = 18
	result.content_margin_top = 7
	result.content_margin_bottom = 7
	return result

static func button(text: String, callback: Callable, height: float = 42.0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = height
	node.add_theme_font_override("font", serif())
	node.add_theme_font_size_override("font_size", 22)
	node.add_theme_color_override("font_color", LIGHT)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_focus_color", Color.WHITE)
	node.add_theme_color_override("font_disabled_color", Color("625f55"))
	node.add_theme_stylebox_override("normal", style(Color(0, 0, 0, 0.18)))
	node.add_theme_stylebox_override("hover", style(Color(0.55, 0.45, 0.25, 0.28), Color("80724f")))
	node.add_theme_stylebox_override("focus", style(Color(0.55, 0.45, 0.25, 0.28), Color("aa9460")))
	node.add_theme_stylebox_override("pressed", style(Color(0.65, 0.53, 0.29, 0.42), GOLD))
	node.add_theme_stylebox_override("disabled", style(Color(0, 0, 0, 0.1)))
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(callback)
	return node

static func panel(parent: Node, title: String, subtitle: String = "") -> VBoxContainer:
	var surface := PanelContainer.new()
	surface.name = "PagePanel"
	surface.position = Vector2(310, 55)
	surface.size = Vector2(660, 610)
	surface.add_theme_stylebox_override("panel", style(Color(0.035, 0.04, 0.039, 0.97), Color("6e6247")))
	parent.add_child(surface)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	surface.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)
	stack.add_child(label(title, 34, GOLD, true))
	if not subtitle.is_empty():
		var description := label(subtitle, 14, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(description)
	var line := HSeparator.new()
	line.modulate = GOLD
	stack.add_child(line)
	return stack

static func spacer(parent: Node) -> void:
	var node := Control.new()
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(node)

static func settings_page(parent: Node, session: Node, back: Callable) -> void:
	var stack := panel(parent, "Settings", "Changes apply immediately and are saved on this device.")
	for entry in [["Master volume", "master"], ["Music volume", "music"], ["Effects volume", "effects"], ["Mouse sensitivity", "sensitivity"]]:
		var key: String = entry[1]
		var row := HBoxContainer.new()
		stack.add_child(row)
		var title := label(entry[0], 17)
		title.custom_minimum_size.x = 205
		row.add_child(title)
		var slider := HSlider.new()
		slider.name = key
		slider.min_value = 1 if key == "sensitivity" else 0
		slider.max_value = 50 if key == "sensitivity" else 100
		slider.step = 1
		slider.value = float(session.settings[key]) * (1.0 if key == "sensitivity" else 100.0)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		var number := label(str(int(slider.value)), 16, GOLD)
		number.custom_minimum_size.x = 40
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(number)
		slider.value_changed.connect(func(value: float):
			number.text = str(int(value))
			session.set_option(key, value if key == "sensitivity" else value / 100.0)
		)
	for entry in [["Fullscreen", "fullscreen"], ["VSync", "vsync"], ["Invert camera Y", "invert_y"]]:
		var key: String = entry[1]
		var toggle := CheckButton.new()
		toggle.name = key
		toggle.text = entry[0]
		toggle.button_pressed = bool(session.settings[key])
		toggle.add_theme_font_size_override("font_size", 17)
		toggle.custom_minimum_size.y = 36
		toggle.toggled.connect(func(value: bool): session.set_option(key, value))
		stack.add_child(toggle)
	spacer(stack)
	stack.add_child(button("Restore defaults", func():
		session.settings = session.DEFAULT_SETTINGS.duplicate()
		session.apply_settings()
		session.save_settings()
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()
		settings_page(parent, session, back)
	))
	var back_button := button("Back", back)
	stack.add_child(back_button)
	focus_later(back_button)

static func controls_page(parent: Node, back: Callable) -> void:
	var stack := panel(parent, "Controls", "Keyboard & mouse / Controller")
	for text in ["Move  —  W A S D / Left stick", "Look  —  Mouse / Right stick", "Light / heavy attack  —  Left click / Shift + Left click", "Guard / gadget attack  —  Right click / Shift + Right click", "Dodge / sprint  —  Tap / hold Space", "Jump  —  F     •     Interact  —  E     •     Lock on  —  Q", "Use item  —  R     •     Cycle items  —  1, 2 / Mouse wheel", "Change weapon  —  Z     •     Change offhand  —  X", "Character stats  —  C     •     Pause  —  Esc / Start", "Menu navigation  —  Arrow keys / D-pad, Enter / A"]:
		stack.add_child(label(text, 16))
	spacer(stack)
	var close := button("Back", back)
	stack.add_child(close)
	focus_later(close)

static func focus_later(node: Control) -> void:
	if is_instance_valid(node) and node.is_inside_tree() and node.is_visible_in_tree():
		node.grab_focus()