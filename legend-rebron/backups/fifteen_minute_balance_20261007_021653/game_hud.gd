extends Control
const Style = preload("res://scripts/ui_style.gd")
var run: Node
var level_label: Label
var xp_label: Label
var xp_bar: ProgressBar
var hp_bar: ProgressBar
var hp_label: Label
var weapon_label: Label
var weapon_level_label: Label
var weapon_ability_label: Label
var movement_hint: Label
var combo: Node
var elapsed := 0.0
var clock_label: Label
var survival_label: Label
var spawner: Node
var boss_bar: ProgressBar
var rank_label: Label
var combo_bar: ProgressBar
var combo_info: Label
var critical_label: Label
var critical_remaining := 0.0
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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameData.settings_changed.connect(refresh_bindings)
	var progress := corner(Rect2(40, 28, 260, 100))
	var progress_stack := VBoxContainer.new()
	progress.add_child(progress_stack)
	progress_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_label = Style.label(progress_stack, "LEVEL 1", 20, Style.PAPER)
	xp_bar = Style.bar(progress_stack, Color("b79550"), 0, 10)
	xp_label = Style.label(progress_stack, "0 / 10 XP", 14, Style.PAPER)
	var top := corner(Rect2(-110, 48, 220, 30), Vector2(0.5, 0))
	clock_label = Style.label(top, "00:00", 24, Style.PAPER)
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var survival_area := corner(Rect2(-220, 16, 440, 30), Vector2(0.5, 0))
	survival_label = Style.label(survival_area, "SURVIVAL", 24, Style.GOLD)
	survival_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	survival_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var boss_area := corner(Rect2(-220, 40, 440, 8), Vector2(0.5, 0))
	boss_bar = Style.bar(boss_area, Color("b92e43"), 100, 8)
	boss_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boss_bar.hide()
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
	combo_info = Style.label(rank_stack, "COMBO / READY", 14, Style.PAPER)
	combo_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var critical_area := corner(Rect2(-286, 218, 242, 64), Vector2(1, 0))
	critical_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	critical_label = Style.label(critical_area, "", 22, Color("ffcf65"))
	critical_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	critical_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	critical_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	critical_label.add_theme_color_override("font_shadow_color", Color(0.15, 0.04, 0.0))
	critical_label.add_theme_constant_override("shadow_offset_x", 2)
	critical_label.add_theme_constant_override("shadow_offset_y", 2)
	critical_label.pivot_offset = Vector2(121, 26)
	critical_label.hide()
	var status := corner(Rect2(40, -156, 320, 126), Vector2(0, 1))
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
	Style.label(weapon, GameData.selected_character.to_upper(), 18, Style.PAPER)
	weapon_label = Style.label(weapon, "WEAPON / NOT ASSIGNED", 15, Style.PAPER)
	weapon_level_label = Style.label(weapon, "", 14, Style.PAPER)
	var ability_area := corner(Rect2(-350, 80, 700, 30), Vector2(0.5, 0))
	weapon_ability_label = Style.label(ability_area, "", 15, Style.PAPER)
	weapon_ability_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	weapon_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label = Style.label(stack, "HP    100 / 100", 14, Style.PAPER)
	hp_bar = Style.bar(stack, Color("a73b29"), 100)
	var help_area := corner(Rect2(-240, -56, 480, 40), Vector2(0.5, 1))
	movement_hint = Style.label(help_area, "", 14, Style.PAPER)
	movement_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refresh_bindings()
func bind_run(model: Node) -> void:
	run = model
	run.changed.connect(refresh_run)
	refresh_run()
func refresh_run() -> void:
	var current: Dictionary = run.stats()
	level_label.text = "LEVEL %d" % run.level
	xp_bar.value = float(run.xp) / run.xp_to_next() * 100.0
	xp_label.text = "%d / %d XP" % [run.xp, run.xp_to_next()]
	hp_label.text = "HP    %s / %s" % [run.catalog.format_number(run.current_health()), run.catalog.format_number(float(current["max_hp"]))]
	hp_bar.value = run.current_health() / maxf(float(current["max_hp"]), 1.0) * 100.0
	weapon_label.text = "WEAPON / " + run.weapon_name().to_upper()
	weapon_level_label.text = "WEAPON LV %d / %d" % [run.weapon_level(), run.MAX_WEAPON_LEVEL]
	if run.weapon_level() < run.MAX_WEAPON_LEVEL:
		var next_level: int = (int(run.level) / run.WEAPON_UPGRADE_INTERVAL + 1) * run.WEAPON_UPGRADE_INTERVAL
		weapon_level_label.text += "\nNEXT: CHARACTER LV %d" % next_level
	else:
		weapon_level_label.text += " / MAX"
	weapon_ability_label.text = "" if run.equipped_weapon_id == "gun" and run.weapon_level() >= 3 else run.weapon_ability()
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
	critical_remaining = maxf(0.0, critical_remaining - delta)
	critical_label.visible = critical_remaining > 0.0
	critical_label.modulate.a = minf(critical_remaining / 0.20, 1.0)
	critical_label.scale = critical_label.scale.lerp(Vector2.ONE, 1.0 - exp(-14.0 * delta))
	refresh_survival()
	elapsed = run.elapsed_time if is_instance_valid(run) else elapsed + delta
	clock_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
func refresh_bindings() -> void:
	movement_hint.text = "%s%s%s%s  Move  /  %s Jump  /  %s Sprint  /  %s Dash" % [
		GameData.key_label("move_forward"), GameData.key_label("move_left"),
		GameData.key_label("move_back"), GameData.key_label("move_right"),
		GameData.key_label("jump"), GameData.key_label("sprint"), GameData.key_label("dash")]


func bind_spawner(model: Node) -> void:
	spawner = model
	spawner.difficulty_changed.connect(refresh_survival)
	refresh_survival()

func refresh_survival() -> void:
	if not is_instance_valid(spawner):
		return
	boss_bar.visible = spawner.boss_phase and is_instance_valid(spawner.boss) and not spawner.completed
	if spawner.completed:
		survival_label.text = "VICTORY"
	elif spawner.boss_phase:
		survival_label.text = "DEFEAT THE BOSS" if is_instance_valid(spawner.boss) else "BOSS INCOMING"
		if is_instance_valid(spawner.boss):
			boss_bar.value = spawner.boss.health / maxf(spawner.boss.max_health, 1.0) * 100.0
	else:
		survival_label.text = "SURVIVAL / %d MONSTERS" % spawner.monsters.size()



func bind_combat(combat: Node) -> void:
	combat.critical_hit.connect(show_critical)
func show_critical(damage: float) -> void:
	critical_remaining = 1.1
	critical_label.text = "CRITICAL!\n%d DAMAGE" % roundi(damage)
	critical_label.modulate.a = 1.0
	critical_label.scale = Vector2.ONE * 1.08
	critical_label.show()

