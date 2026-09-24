extends Control
const Style = preload("res://scripts/ui_style.gd")
var run: Node
var heading: Label
var cards: GridContainer
var choice_buttons: Array[Button] = []
func _ready() -> void:
	hide()
	var shade := ColorRect.new()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.045, 0.95)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	var center := CenterContainer.new()
	margin.add_child(center)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 22)
	center.add_child(stack)
	var title := Style.label(stack, "LEVEL UP", 18, Style.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading = Style.label(stack, "Choose one item", 40)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := Style.label(stack, "Choose one. Its bonus is yours for this run.", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cards = GridContainer.new()
	cards.columns = 3
	cards.add_theme_constant_override("h_separation", 18)
	stack.add_child(cards)
	var help := Style.label(stack, "Press 1, 2 or 3 to choose  /  Game paused", 16, Color("a3aab4"))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(Control.new())
func bind_run(model: Node) -> void:
	run = model
func refresh() -> void:
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	choice_buttons.clear()
	visible = run != null and not run.offers.is_empty()
	if not visible:
		return
	heading.text = "Level %d  /  Choose one item" % run.reward_level
	for index in range(run.offers.size()):
		var id: String = run.offers[index]
		var item: Dictionary = run.catalog.item_for(id)
		var color: Color = run.catalog.rarity_color(item["rarity"])
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(285, 310)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var frame := Style.box(Color("1b2029"), color, 12)
		frame.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", frame)
		cards.add_child(panel)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 18)
		panel.add_child(stack)
		var rarity_label := Style.label(stack, run.catalog.rarity_name(item["rarity"]).to_upper(), 16, color)
		rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var name_label := Style.label(stack, item["name"], 28)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var count := Style.label(stack, "Owned: %d  →  %d" % [run.stack_count(id), run.stack_count(id) + 1], 16, color)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var effects := Style.label(stack, run.catalog.describe(item) + "\nper stack", 20)
		effects.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effects.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var button := Style.button(stack, "Choose [%d]" % (index + 1), _choose.bind(id, run.offer_generation))
		button.add_theme_stylebox_override("normal", Style.box(Color("2a303b"), color))
		choice_buttons.append(button)
	choice_buttons[0].grab_focus()
func _choose(id: String, generation: int) -> void:
	if not visible or generation != run.offer_generation:
		return
	for button in choice_buttons:
		button.disabled = true
	run.choose_item(id, generation)
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index := -1
		match event.physical_keycode:
			KEY_1, KEY_KP_1: index = 0
			KEY_2, KEY_KP_2: index = 1
			KEY_3, KEY_KP_3: index = 2
		if index >= 0 and index < run.offers.size():
			_choose(run.offers[index], run.offer_generation)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
