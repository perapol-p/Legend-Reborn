extends Node3D
var source: Node
var damage := 4.0
var critical := false
var source_weapon := ""
var radius := 3.0
var remaining := 2.0
var pulse := 0.0
var model: Node3D
func _ready() -> void:
	add_to_group("weapon_tornadoes")
	model = Node3D.new()
	add_child(model)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.25, 0.8, 1.0, 0.35)
	for i in range(5):
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		var size := 0.22 + float(i) * radius * 0.12
		mesh.inner_radius = size
		mesh.outer_radius = size + 0.12
		ring.mesh = mesh
		ring.material_override = material
		ring.position.y = float(i) * 0.38 - 0.7
		ring.position.x = sin(float(i)) * 0.2
		model.add_child(ring)
func _physics_process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0 or not is_instance_valid(source):
		queue_free()
		return
	model.rotation.y += delta * 7.0
	pulse -= delta
	var tick := pulse <= 0.0
	if tick:
		pulse = 0.35
	for body in source.damageables(global_position, radius):
		if body is CharacterBody3D and not body.is_queued_for_deletion():
			var offset: Vector3 = global_position - body.global_position
			offset.y = 0.0
			if offset.length() > 0.3:
				body.move_and_collide(offset.normalized() * minf(offset.length(), 5.0 * delta))
		if tick:
			source.deal_hit(body, damage, source_weapon, false, critical)

