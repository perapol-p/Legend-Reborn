extends Control
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameData.settings_changed.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()
func _draw() -> void:
	var center := size * 0.5
	var radius: float = GameData.crosshair_size * 0.5
	var color: Color = GameData.CROSSHAIR_COLORS[GameData.crosshair_color]
	var outline := Color(1, 1, 1, 0.7) if GameData.crosshair_color == "black" else Color(0, 0, 0, 0.75)
	if GameData.crosshair_style == "dot":
		var dot_radius := maxf(1.5, radius * 0.3)
		draw_circle(center, dot_radius + 1.0, outline)
		draw_circle(center, dot_radius, color)
		return
	var gap := radius * 0.4 if GameData.crosshair_style == "gap" else 0.0
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var start: Vector2 = center + direction * gap
		var finish: Vector2 = center + direction * radius
		draw_line(start, finish, outline, 4.0)
		draw_line(start, finish, color, 2.0)
