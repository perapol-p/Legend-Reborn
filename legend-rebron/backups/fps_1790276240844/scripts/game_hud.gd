extends Control
const Style = preload("res://scripts/ui_style.gd")
signal level_up_requested
var run: Node
var level_label: Label
var xp_label: Label
var xp_bar: ProgressBar
var hp_label: Label
var weapon_label: Label
var level_button: Button
var combo: Node
var elapsed := 0.0
var clock_label: Label
var rank_label: Label
var combo_bar: ProgressBar
var combo_info: Label
var flames: CPUParticles2D
func corner(rect: Rect2, anchor: Vector2 = Vector2.ZERO) -> Control:
	var n := Control.new()
	add_child(n)
	n.anchor_left = anchor.x
	n.anchor_right = anchor.x
	n.anchor_top = anchor.y
	n.anchor_bottom = anchor.y
	n.offset_left = rect.position.x
	n.offset_top = rect.position.y
	n.offset_right = rect.end.x
	n.offset_bottom = rect.end.y
	return n
func _ready() -> void:
	var background := ColorRect.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("e6e8e5")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress := corner(Rect2(40, 28, 260, 100))
	var progress_stack := VBoxContainer.new()
	progress.add_child(progress_stack)
	progress_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_label = Style.label(progress_stack, "LEVEL 1", 20, Style.INK)
	xp_bar = Style.bar(progress_stack, Color("b79550"), 0, 10)
	xp_label = Style.label(progress_stack, "0 / 10 XP", 14, Style.INK)
	var top := corner(Rect2(-110, 25, 220, 60), Vector2(0.5, 0))
	clock_label = Style.label(top, "00:00", 28, Style.INK)
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rank_area := corner(Rect2(-286, 72, 242, 175), Vector2(1, 0))
	flames = CPUParticles2D.new()
	rank_area.add_child(flames)
	flames.position = Vector2(121, 84)
	flames.amount = 85
	flames.lifetime = 0.7
	flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flames.emission_rect_extents = Vector2(72, 8)
	flames.direction = Vector2(0, -1)
	flames.spread = 22
	flames.gravity = Vector2(0, -60)
	flames.initial_velocity_min = 45
	flames.initial_velocity_max = 115
	flames.scale_amount_min = 3
	flames.scale_amount_max = 9
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 0.85, 0.22, 0.9), Color(1, 0.27, 0.04, 0.65), Color(0.7, 0.05, 0, 0)])
	gradient.offsets = PackedFloat32Array([0, 0.45, 1])
	flames.color_ramp = gradient
	flames.emitting = false
	var rank_stack := VBoxContainer.new()
	rank_area.add_child(rank_stack)
	rank_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rank_label = Style.label(rank_stack, "—", 68, Color("ec763e"))
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_bar = Style.bar(rank_stack, Color("ed8649"), 0, 11)
	combo_info = Style.label(rank_stack, "COMBO / READY", 14, Style.INK)
	combo_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var status := corner(Rect2(40, -200, 320, 170), Vector2(0, 1))
	var stack := VBoxContainer.new()
	status.add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	stack.add_child(row)
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(64, 60)
	portrait.add_theme_stylebox_override("panel", Style.box(Style.INK, Style.GOLD))
	row.add_child(portrait)
	var initial := Style.label(portrait, GameData.selected_character.left(1).to_upper(), 30)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var weapon := VBoxContainer.new()
	row.add_child(weapon)
	Style.label(weapon, GameData.selected_character.to_upper(), 18, Style.INK)
	weapon_label = Style.label(weapon, "WEAPON / NOT ASSIGNED", 15, Style.INK)
	hp_label = Style.label(stack, "HP    100 / 100", 14, Style.INK)
	Style.bar(stack, Color("a73b29"), 100)
	Style.label(stack, "MP      50 / 50", 14, Style.INK)
	Style.bar(stack, Color("427e92"), 100)
	var test_area := corner(Rect2(-410, -190, 370, 160), Vector2(1, 1))
	var tests := VBoxContainer.new()
	test_area.add_child(tests)
	tests.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Style.label(tests, "TEST CONTROLS", 14, Style.INK)
	var buttons := HBoxContainer.new()
	tests.add_child(buttons)
	Style.button(buttons, "Hit [J]", func(): combo.register_hit())
	Style.button(buttons, "Kill [K]", func(): combo.register_kill())
	Style.button(buttons, "Reset [R]", func(): combo.reset())
	level_button = Style.button(tests, "Level up [L]", func(): level_up_requested.emit())
	Style.label(tests, "ESC / Pause    •    Decay: one rank / 4s", 14, Style.INK)
func bind_run(model: Node) -> void:
	run = model
	run.changed.connect(refresh_run)
	refresh_run()
func refresh_run() -> void:
	var current: Dictionary = run.stats()
	level_label.text = "LEVEL %d" % run.level
	xp_bar.value = float(run.xp) / run.xp_to_next() * 100.0
	xp_label.text = "%d / %d XP" % [run.xp, run.xp_to_next()]
	if run.remaining_count() == 0:
		xp_label.text += "  /  All items collected"
	hp_label.text = "HP    %s / %s" % [run.catalog.format_number(float(current["max_hp"])), run.catalog.format_number(float(current["max_hp"]))]
	weapon_label.text = "WEAPON / " + run.catalog.weapon_name(run.character_name).to_upper()
func bind_combo(model: Node) -> void:
	combo = model
	combo.changed.connect(refresh_combo)
	refresh_combo()
func refresh_combo() -> void:
	var rank: int = combo.rank_index()
	rank_label.text = "—" if rank < 0 else combo.RANKS[rank]
	combo_bar.value = combo.remaining / combo.decay_seconds * 100.0
	combo_info.text = "COMBO / READY" if rank < 0 else "%.1fs   /   %d POINTS" % [combo.remaining, combo.points]
	flames.emitting = rank == 8
	rank_label.add_theme_color_override("font_color", Color("f36b26") if rank == 8 else Color("b9572b"))
func _process(delta: float) -> void:
	elapsed += delta
	clock_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and combo != null:
		match event.physical_keycode:
			KEY_J: combo.register_hit()
			KEY_K: combo.register_kill()
			KEY_R: combo.reset()
			KEY_L: level_up_requested.emit()
