extends CanvasLayer
## Native Godot UI: no external art, fonts, or downloads are required.
const GOLD = Color("dabb79")
const MUTED = Color("929caa")
const INK = Color("111820")
const COLORS = {"Hp": Color("ed7883"), "Atk": Color("e6ac70"), "Spd": Color("76bdeb"), "Stamina": Color("7dcca1"), "Def": Color("b2a2e8")}
const DETAILS = {"Hp": "Maximum health", "Atk": "Weapon damage", "Spd": "Movement speed", "Stamina": "Attack, dodge & sprint energy", "Def": "Armor / damage reduction"}
var player: Node
var stats: Node
var progression: Node
var overlay: Control
var panel: PanelContainer
var rows: Dictionary = {}
var level_label: Label
var point_label: Label
var xp_label: Label
var xp_bar: ProgressBar
var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var hud_xp: ProgressBar
var hp_label: Label
var stamina_label: Label
var hud_level: Label
var notification: Label
var status_label: Label
var notice_seconds: float = 0.0
var opened: bool = false
var previous_mouse: int = Input.MOUSE_MODE_CAPTURED
var previous_pause: bool = false
var hud: PanelContainer

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent()
	stats = player.stats
	progression = get_node("/root/CharacterProgression")
	build_ui()
	progression.changed.connect(refresh)
	progression.gained_experience.connect(on_experience)
	stats.stamina_changed.connect(refresh_vitals)
	stats.exhausted.connect(func(): show_notice("Not enough stamina", COLORS.Stamina))
	player.health_system.health_updated.connect(func(_amount): refresh_vitals())
	player.death_started.connect(func(): hud.hide())
	refresh()

func box(color: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func label(text: String, size: int = 16, color: Color = Color.WHITE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

func button(text: String) -> Button:
	var node := Button.new()
	node.text = text
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 16)
	node.add_theme_color_override("font_color", GOLD)
	node.add_theme_stylebox_override("normal", box(Color("29302c"), Color("766444"), 8))
	node.add_theme_stylebox_override("hover", box(Color("3e4332"), GOLD, 8))
	node.add_theme_stylebox_override("focus", box(Color("3e4332"), GOLD, 8))
	node.add_theme_stylebox_override("pressed", box(Color("565139"), GOLD, 8))
	node.add_theme_stylebox_override("disabled", box(Color("1b2129"), Color("303944"), 8))
	return node

func bar(color: Color, height: float = 8.0) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = Vector2(0, height)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background := box(Color("080d13"), Color("293443"), 4)
	background.content_margin_top = 0
	background.content_margin_bottom = 0
	var fill := box(color, color, 4)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	node.add_theme_stylebox_override("background", background)
	node.add_theme_stylebox_override("fill", fill)
	return node

func build_ui() -> void:
	hud = PanelContainer.new()
	hud.position = Vector2(22, 20)
	hud.custom_minimum_size = Vector2(294, 0)
	hud.add_theme_stylebox_override("panel", box(Color(0.045, 0.065, 0.09, 0.93), Color("4f493b")))
	add_child(hud)
	var hud_stack := VBoxContainer.new()
	hud_stack.add_theme_constant_override("separation", 7)
	hud.add_child(hud_stack)
	hud_level = label("", 15, GOLD)
	hud_stack.add_child(hud_level)
	hp_label = label("", 13, COLORS.Hp)
	hud_stack.add_child(hp_label)
	hp_bar = bar(COLORS.Hp)
	hud_stack.add_child(hp_bar)
	stamina_label = label("", 13, COLORS.Stamina)
	hud_stack.add_child(stamina_label)
	stamina_bar = bar(COLORS.Stamina)
	hud_stack.add_child(stamina_bar)
	hud_xp = bar(GOLD, 4)
	hud_stack.add_child(hud_xp)
	var open_button := button("C  /  CHARACTER")
	open_button.pressed.connect(toggle_menu)
	hud_stack.add_child(open_button)
	notification = label("", 19, GOLD)
	notification.position = Vector2(338, 30)
	add_child(notification)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box(INK, Color("776749"), 18))
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 13)
	margin.add_child(stack)
	var top := HBoxContainer.new()
	stack.add_child(top)
	var eyebrow := label("C H A R A C T E R   /   P R O G R E S S I O N", 13, GOLD)
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(eyebrow)
	var close_button := button("Close  [C]")
	close_button.pressed.connect(toggle_menu)
	top.add_child(close_button)
	stack.add_child(label("Forge your own path", 32))
	stack.add_child(label("Defeat enemies. Earn experience. Shape your build.", 15, MUTED))
	var summary := HBoxContainer.new()
	stack.add_child(summary)
	level_label = label("", 23, GOLD)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(level_label)
	point_label = label("", 21, GOLD)
	summary.add_child(point_label)
	xp_bar = bar(GOLD, 9)
	stack.add_child(xp_bar)
	xp_label = label("", 13, MUTED)
	stack.add_child(xp_label)
	for stat in progression.KEYS:
		build_row(stack, stat)
	status_label = label("", 13, MUTED)
	stack.add_child(status_label)
	stack.add_child(label("3 points per level  /  Upgrade costs rise every 5 ranks\nGame paused while this panel is open  /  C or Esc to return", 13, MUTED))
	overlay.hide()
	get_viewport().size_changed.connect(layout_panel)
	call_deferred("layout_panel")

func build_row(stack: VBoxContainer, stat: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", box(Color("1a232e"), Color("303c4b"), 9))
	stack.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load("res://ui/stats/icons/" + stat.to_lower() + ".svg")
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(names)
	var title := label(stat.to_upper(), 18, COLORS[stat])
	names.add_child(title)
	names.add_child(label(DETAILS[stat], 12, MUTED))
	var value_label := label("", 20)
	value_label.custom_minimum_size.x = 146
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	var upgrade_button := button("+")
	upgrade_button.custom_minimum_size.x = 112
	upgrade_button.pressed.connect(func():
		if progression.upgrade(stat):
			show_notice(stat + " increased", COLORS[stat])
	)
	row.add_child(upgrade_button)
	rows[stat] = {"value": value_label, "button": upgrade_button, "title": title}

func layout_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	panel.size = Vector2(750, 0)
	var factor: float = minf(1.0, minf((viewport_size.x - 28.0) / 750.0, (viewport_size.y - 28.0) / maxf(panel.size.y, 660.0)))
	panel.scale = Vector2.ONE * maxf(0.1, factor)
	panel.position = (viewport_size - panel.size * panel.scale) * 0.5

func refresh() -> void:
	level_label.text = "LEVEL  %02d" % progression.level
	point_label.text = "%d POINTS AVAILABLE" % progression.points
	xp_bar.max_value = progression.xp_required()
	xp_bar.value = progression.experience
	xp_label.text = "%d / %d EXP  /  NEXT LEVEL +3 POINTS" % [progression.experience, progression.xp_required()]
	hud_level.text = "LV. %02d    /    %d STAT POINTS" % [progression.level, progression.points]
	hud_xp.max_value = progression.xp_required()
	hud_xp.value = progression.experience
	for stat in rows:
		var current: float = progression.value(stat)
		var next: float = current + float(progression.STEP[stat])
		var suffix: String = "%" if stat == "Spd" else ""
		rows[stat].value.text = "%d%s  >  %d%s" % [current, suffix, next, suffix]
		rows[stat].title.text = "%s   /   %02d" % [stat.to_upper(), progression.ranks[stat]]
		rows[stat].button.disabled = not progression.can_upgrade(stat)
		rows[stat].button.text = "+  %d PT" % progression.upgrade_cost(stat)
		if int(progression.ranks[stat]) >= progression.MAX_RANK:
			rows[stat].value.text = "%d%s" % [current, suffix]
			rows[stat].button.text = "MAX"
	status_label.text = "Damage reduction: %.1f%%  /  Progress saved automatically" % (100.0 * progression.value("Def") / (100.0 + progression.value("Def")))
	if progression.save_error:
		status_label.text = "Save unavailable - progress is kept for this session only."
	refresh_vitals()

func refresh_vitals() -> void:
	hp_bar.max_value = player.health_system.total_health
	hp_bar.value = player.health_system.current_health
	hp_label.text = "HP   %d / %d" % [ceilf(hp_bar.value), hp_bar.max_value]
	stamina_bar.max_value = progression.value("Stamina")
	stamina_bar.value = stats.stamina
	stamina_label.text = "STAMINA   %d / %d" % [ceilf(stats.stamina), stamina_bar.max_value]

func toggle_menu() -> void:
	if player.is_dead:
		return
	opened = not opened
	overlay.visible = opened
	if opened:
		previous_pause = get_tree().paused
		previous_mouse = Input.mouse_mode
		player.end_sprint()
		player.end_guard()
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		refresh()
		layout_panel()
	else:
		get_tree().paused = previous_pause
		Input.mouse_mode = previous_mouse

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C or event.keycode == KEY_C or (opened and event.is_action_pressed("ui_cancel")):
			toggle_menu()
			get_viewport().set_input_as_handled()

func on_experience(amount: int, levels: int) -> void:
	var message: String = "+%d EXP" % amount
	if levels > 0:
		message += "   LEVEL UP!  +%d POINTS  [C]" % (levels * 3)
	show_notice(message, GOLD)

func show_notice(message: String, color: Color) -> void:
	notification.text = message
	notification.add_theme_color_override("font_color", color)
	notice_seconds = 3.0

func _process(delta: float) -> void:
	notice_seconds = maxf(0.0, notice_seconds - delta)
	notification.visible = notice_seconds > 0.0 and not opened
