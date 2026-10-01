extends Control
var combat: Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_delta: float) -> void:
	visible = combat != null and combat.weapon_id == "gun" and combat.weapon_level() >= 3 and (combat.charge_ready or combat.empowered > 0.0) and combat.can_act()
	if visible:
		queue_redraw()
func arc_points(center: Vector2, side: float, start: float, end: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius := maxf(18.0, GameData.crosshair_size * 0.5 + 10.0)
	for i in range(33):
		var fraction := lerpf(start, end, float(i) / 32.0)
		var angle := deg_to_rad(40.0 - fraction * 80.0)
		points.append(center + Vector2(side * cos(angle), sin(angle)) * radius)
	return points
func _draw() -> void:
	if combat == null:
		return
	var center := size * 0.5
	var fill := clampf(combat.charge_time / 1.5, 0.0, 1.0)
	var burst: bool = combat.empowered > 0.0
	if burst:
		fill = clampf(combat.empowered / 5.0, 0.0, 1.0)
	var color := Color("55f54e") if fill >= 0.9 or burst else Color("f3ce61")
	for side in [-1.0, 1.0]:
		draw_polyline(arc_points(center, side, 0.0, 1.0), Color(0.02, 0.03, 0.04, 0.9), 6.0, true)
		draw_polyline(arc_points(center, side, 0.0, 1.0), Color(0.24, 0.28, 0.31, 0.85), 3.0, true)
		draw_polyline(arc_points(center, side, 0.9, 1.0), Color(0.2, 0.8, 0.24, 0.65), 3.0, true)
		if fill > 0.001:
			draw_polyline(arc_points(center, side, 0.0, fill), color, 3.0, true)