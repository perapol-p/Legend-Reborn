extends PanelContainer
const Style = preload("res://scripts/ui_style.gd")
const Progression = preload("res://scripts/weapon_progression.gd")
var run: Node
var title: Label
var values: Label
func _ready() -> void:
	name = "WeaponStatsPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", Style.box(Color("141c25"), Style.GOLD))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	add_child(stack)
	title = Style.label(stack, "", 20, Style.GOLD)
	values = Style.label(stack, "", 15)
	values.add_theme_constant_override("line_spacing", 5)
func bind_run(model: Node) -> void:
	run = model
	run.changed.connect(refresh)
	refresh()
func refresh() -> void:
	if run == null: return
	var id: String = run.upgrade_weapon_id if run.reward_phase == "weapon" else run.equipped_weapon_id
	title.text = Progression.display_name(id)
	values.text = Progression.stat_text(run.weapon_stats(id), id)
