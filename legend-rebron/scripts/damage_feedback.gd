extends Control
const VIGNETTE = preload("res://shaders/damage_vignette.gdshader")
const HIT_DURATION := 0.85
var player: CharacterBody3D
var camera: Camera3D
var hits: Array[Dictionary] = []
var flash_time := 0.0
var flash_strength := 0.0
var vignette_material: ShaderMaterial
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border := ColorRect.new()
	border.name = "DamageBorder"
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_material = ShaderMaterial.new()
	vignette_material.shader = VIGNETTE
	border.material = vignette_material
	# Put the indicator arcs above the border while keeping the center unobscured.
	move_child(border, 0)
	hide()
func bind_player(body: CharacterBody3D) -> void:
	player = body
	camera = player.get_node("Head/Camera3D")
	player.damage_received.connect(_on_damage_received)
func _on_damage_received(amount: float, source_position: Vector3) -> void:
	flash_time = 0.25
	flash_strength = clampf(amount / 20.0, 0.45, 1.0)
	if source_position != Vector3.INF:
		hits.append({"position": source_position, "time": HIT_DURATION, "strength": flash_strength})
		if hits.size() > 8:
			hits.pop_front()
	show()
	_update_shader()
	queue_redraw()
func screen_direction(source_position: Vector3) -> Vector2:
	var offset := source_position - player.global_position
	offset.y = 0.0
	if offset.length_squared() < 0.0001:
		return Vector2.ZERO
	offset = offset.normalized()
	var forward := -camera.global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = -player.global_basis.z
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	return Vector2(offset.dot(right), -offset.dot(forward)).normalized()
func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if get_tree().paused or player.run.finished:
		hide()
		return
	flash_time = maxf(0.0, flash_time - delta)
	for hit in hits:
		hit["time"] -= delta
	hits = hits.filter(func(hit): return hit["time"] > 0.0)
	visible = flash_time > 0.0 or not hits.is_empty()
	if visible:
		_update_shader()
		queue_redraw()
func _update_shader() -> void:
	vignette_material.set_shader_parameter("flash", flash_strength * pow(flash_time / 0.25, 2.0))
	var direction := Vector2.ZERO
	var strength := 0.0
	if not hits.is_empty():
		var hit: Dictionary = hits.back()
		direction = screen_direction(hit["position"])
		strength = float(hit["strength"]) * pow(float(hit["time"]) / HIT_DURATION, 0.8)
	vignette_material.set_shader_parameter("hit_direction", direction)
	vignette_material.set_shader_parameter("direction_strength", strength)
func _draw() -> void:
	if not is_instance_valid(player):
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	for hit in hits:
		var direction := screen_direction(hit["position"])
		if direction == Vector2.ZERO:
			continue
		var alpha := pow(float(hit["time"]) / HIT_DURATION, 0.8)
		var angle := direction.angle()
		draw_arc(center, radius, angle - 0.30, angle + 0.30, 24, Color(1.0, 0.08, 0.08, alpha * 0.18), 18.0, true)
		draw_arc(center, radius, angle - 0.27, angle + 0.27, 24, Color(1.0, 0.14, 0.10, alpha * 0.9), 5.0, true)

