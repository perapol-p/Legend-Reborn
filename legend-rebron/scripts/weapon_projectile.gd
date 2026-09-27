extends Node3D
var direction := Vector3.FORWARD
var speed := 30.0
var damage := 10.0
var kind := "bow"
var source: Node
var source_weapon := ""
var excluded: Array[RID] = []
var remaining := 5.0
var hit_radius := 0.04
var piercing := false
var splash := 0.0
var struck: Array[RID] = []
func _ready() -> void:
	add_to_group("weapon_projectiles")
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
	elif kind == "sword_wave":
		var wave := BoxMesh.new()
		wave.size = Vector3(hit_radius * 2.6, hit_radius * 0.7, 0.15)
		visual.mesh = wave
		material.albedo_color = Color(0.2, 0.9, 1.0)
	elif kind == "rpg":
		var rocket := CylinderMesh.new()
		rocket.top_radius = 0.0
		rocket.bottom_radius = 0.14
		rocket.height = 0.65
		visual.mesh = rocket
		visual.rotation.x = -PI / 2
		material.albedo_color = Color(1.0, 0.5, 0.1)
	else:
		var orb := SphereMesh.new()
		orb.radius = maxf(hit_radius, 0.15)
		orb.height = orb.radius * 2.0
		visual.mesh = orb
		material.albedo_color = Color(0.9, 0.2, 1.0) if kind == "nuke" else Color(0.25, 0.65, 1)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	add_child(visual)
func _physics_process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var displacement := direction * speed * delta
	var steps := maxi(1, ceili(displacement.length() / maxf(hit_radius, 0.12)))
	var step := displacement / float(steps)
	for i in range(steps):
		var next := global_position + step
		var query := PhysicsRayQueryParameters3D.create(global_position, next, 1, excluded + struck)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			if impact(hit["collider"], hit["position"]):
				return
		if hit_radius > 0.1:
			var sphere := SphereShape3D.new()
			sphere.radius = hit_radius
			var shape_query := PhysicsShapeQueryParameters3D.new()
			shape_query.shape = sphere
			shape_query.transform = Transform3D(Basis.IDENTITY, next)
			shape_query.collision_mask = 1
			shape_query.exclude = excluded + struck
			for overlap in get_world_3d().direct_space_state.intersect_shape(shape_query, 16):
				if impact(overlap["collider"], next):
					return
		global_position = next
func impact(body: CollisionObject3D, point: Vector3) -> bool:
	if struck.has(body.get_rid()):
		return false
	struck.append(body.get_rid())
	var damageable := body.has_method("take_damage")
	if is_instance_valid(source):
		if damageable:
			source.deal_hit(body, damage, source_weapon)
		if splash > 0.0:
			source.explode(point - direction * 0.08, splash, damage, body)
	if piercing and damageable:
		return false
	queue_free()
	return true
