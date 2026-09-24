extends VBoxContainer
const Style = preload("res://scripts/ui_style.gd")
const Crosshair = preload("res://scripts/crosshair.gd")
var page := "General"
var content: VBoxContainer
var status: Label
var waiting_action := ""
var binding_buttons: Dictionary = {}
var style_picker: OptionButton
var color_picker: OptionButton
var size_slider: HSlider
func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var tabs := HBoxContainer.new()
	add_child(tabs)
	for title in ["General", "Keyboard", "Crosshair"]:
		Style.button(tabs, title, show_page.bind(title))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 270
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	status = Style.label(self, "Changes are saved automatically.", 14, Style.GOLD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Style.button(self, "Restore defaults", _restore)
	show_page(page)
	visibility_changed.connect(func():
		if not is_visible_in_tree():
			cancel_rebind())
func _exit_tree() -> void:
	cancel_rebind()
func cancel_rebind() -> void:
	if not waiting_action.is_empty():
		waiting_action = ""
		GameData.rebinding_active = false
		for action in binding_buttons:
			if is_instance_valid(binding_buttons[action]):
				binding_buttons[action].disabled = false
				binding_buttons[action].text = GameData.key_label(action)
func show_page(title: String) -> void:
	cancel_rebind()
	page = title
	binding_buttons.clear()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	match page:
		"General": _general()
		"Keyboard": _keyboard()
		"Crosshair": _crosshair()
func _row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	content.add_child(row)
	var name_label := Style.label(row, label_text, 17)
	name_label.custom_minimum_size.x = 175
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row
func _slider(label_text: String, current: float, minimum: float, maximum: float, callback: Callable) -> HSlider:
	var row := _row(label_text)
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 200
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 1
	slider.value = current
	row.add_child(slider)
	var number := Style.label(row, str(int(current)), 17)
	number.custom_minimum_size.x = 36
	slider.value_changed.connect(func(value):
		number.text = str(int(value))
		callback.call(value))
	return slider
func _general() -> void:
	_slider("Master volume", GameData.master_volume * 100, 0, 100, func(v): _set_number("master_volume", v / 100.0))
	_slider("Music volume", GameData.music_volume * 100, 0, 100, func(v): _set_number("music_volume", v / 100.0))
	_slider("Effects volume", GameData.effects_volume * 100, 0, 100, func(v): _set_number("effects_volume", v / 100.0))
	_slider("Mouse sensitivity", GameData.mouse_sensitivity * 100, 1, 100, func(v): _set_number("mouse_sensitivity", v / 100.0))
	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Fullscreen"
	fullscreen_toggle.button_pressed = GameData.fullscreen
	content.add_child(fullscreen_toggle)
	fullscreen_toggle.toggled.connect(func(value):
		GameData.fullscreen = value
		_commit())
	var invert_toggle := CheckButton.new()
	invert_toggle.text = "Invert mouse Y"
	invert_toggle.button_pressed = GameData.invert_y
	content.add_child(invert_toggle)
	invert_toggle.toggled.connect(func(value):
		GameData.invert_y = value
		_commit())
func _set_number(property: String, value: float) -> void:
	GameData.set(property, value)
	_commit()
func _commit() -> void:
	GameData.apply_settings()
	GameData.save_settings()
func _keyboard() -> void:
	Style.label(content, "Select an action, then press a key. Escape cancels.", 16)
	for action in GameData.ACTIONS:
		var row := _row(GameData.ACTIONS[action]["label"])
		var button := Style.button(row, GameData.key_label(action), begin_rebind.bind(action))
		button.custom_minimum_size.x = 155
		binding_buttons[action] = button
	Style.label(content, "Esc: pause / resume.  1 / 2 / 3: choose a level-up item.", 14, Style.GOLD)
func begin_rebind(action: String) -> void:
	waiting_action = action
	GameData.rebinding_active = true
	status.text = "Press a key for " + GameData.ACTIONS[action]["label"] + " (Esc cancels)"
	for name in binding_buttons:
		binding_buttons[name].disabled = true
	binding_buttons[action].text = "Press a key..."
func _input(event: InputEvent) -> void:
	if waiting_action.is_empty() or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var action := waiting_action
		if event.physical_keycode == KEY_ESCAPE:
			status.text = "Binding unchanged."
		elif event.physical_keycode != KEY_NONE:
			status.text = GameData.rebind(action, event.physical_keycode)
		else:
			return
		cancel_rebind()
		for name in binding_buttons:
			binding_buttons[name].disabled = false
			binding_buttons[name].text = GameData.key_label(name)
		get_viewport().set_input_as_handled()
func _crosshair() -> void:
	var preview_box := PanelContainer.new()
	preview_box.add_theme_stylebox_override("panel", Style.box(Color("323946")))
	content.add_child(preview_box)
	var preview := Crosshair.new()
	preview.custom_minimum_size = Vector2(250, 90)
	preview_box.add_child(preview)
	var style_row := _row("Shape")
	style_picker = OptionButton.new()
	style_picker.custom_minimum_size.x = 225
	for title in ["Plus (+)", "Dot", "Plus with center gap"]:
		style_picker.add_item(title)
	style_picker.select(GameData.CROSSHAIR_STYLES.find(GameData.crosshair_style))
	style_row.add_child(style_picker)
	style_picker.item_selected.connect(func(index):
		GameData.crosshair_style = GameData.CROSSHAIR_STYLES[index]
		_commit())
	var color_row := _row("Color")
	color_picker = OptionButton.new()
	color_picker.custom_minimum_size.x = 225
	for name in GameData.CROSSHAIR_COLORS:
		color_picker.add_item(name.capitalize())
	color_picker.select(GameData.CROSSHAIR_COLORS.keys().find(GameData.crosshair_color))
	color_row.add_child(color_picker)
	color_picker.item_selected.connect(func(index):
		GameData.crosshair_color = GameData.CROSSHAIR_COLORS.keys()[index]
		_commit())
	size_slider = _slider("Size", GameData.crosshair_size, 6, 48, func(value):
		GameData.crosshair_size = value
		_commit())
func _restore() -> void:
	GameData.restore_defaults()
	status.text = "Default settings restored."
	show_page(page)
