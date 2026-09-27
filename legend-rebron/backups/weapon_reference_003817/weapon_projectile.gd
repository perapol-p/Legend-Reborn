extends Node3D
var direction := Vector3.FORWARD
var speed := 30.0
var damage := 10.0
var kind := "bow"
var source: Node
var excluded: Array[RID] = []
var remaining := 5.0
func _ready() -> void:
	var visual := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	if kind == "bow":
		var arrow := BoxMesh.new()
		arrow.size = Vector3(0.025, 0.025, 0.55)
		visual.mesh = arrow
		material.albedo_color = Color(0.7, 0.4, 0.13)
		var tip := MeshInstance3D.new()
		var tip_mesh := PrismMesh.new()
		tip_mesh.size = Vector3(0.1, 0.18, 0.025)
		tip.mesh = tip_mesh
		tip.rotation.x = -PI / 2
		tip.position.z = -0.3
		visual.add_child(tip)
	else:
		var orb := SphereMesh.new()
		orb.radius = 0.13
		orb.height = 0.26
		visual.mesh = orb
		material.albedo_color = Color(0.25, 0.65, 1)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	add_child(visual)
func _physics_process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var next := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next, 1, excluded)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if is_instance_valid(source):
			source.deal_hit(hit["collider"], damage)
		queue_free()
		return
	global_position = next

