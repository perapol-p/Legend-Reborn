extends Node3D
var player: CharacterBody3D
var velocity := Vector3.ZERO
var damage := 6.0
var kind := "arrow"
var source_position := Vector3.ZERO
var excluded: Array[RID] = []
var gravity := 3.0
var remaining := 3.0
var max_distance := 32.0
var distance_travelled := 0.0
var collision_radius := 0.07
func _ready() -> void:
	add_to_group("enemy_projectiles")
	var visual := MeshInstance3D.new()
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if kind == "arrow":
		var shaft := CylinderMesh.new()
		shaft.top_radius = 0.018
		shaft.bottom_radius = 0.018
		shaft.height = 0.65
		visual.mesh = shaft
		visual.rotation.x = PI / 2
		material.albedo_color = Color("ddb668")
		var tip := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.06
		cone.height = 0.15
		tip.mesh = cone
		tip.rotation.x = -PI / 2
		tip.position.z = -0.38
		tip.material_override = material
		add_child(tip)
	else:
		collision_radius = 0.20
		var sphere := SphereMesh.new()
		sphere.radius = 0.22
		sphere.height = 0.44
		visual.mesh = sphere
		material.albedo_color = Color(1.0, 0.45, 0.06)
		var core := MeshInstance3D.new()
		var core_mesh := SphereMesh.new()
		core_mesh.radius = 0.15
		core_mesh.height = 0.30
		core.mesh = core_mesh
		core.position.z = -0.12
		var core_material := StandardMaterial3D.new()
		core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		core_material.albedo_color = Color(1.0, 0.95, 0.50)
		core.material_override = core_material
		add_child(core)
	visual.material_override = material
	add_child(visual)
	_create_trail()
	_orient()
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.run.finished:
		queue_free()
		return
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var old_velocity := velocity
	velocity.y -= gravity * delta
	var displacement := (old_velocity + velocity) * 0.5 * delta
	var length := minf(displacement.length(), max_distance - distance_travelled)
	if length <= 0.0:
		queue_free()
		return
	displacement = displacement.normalized() * length
	_orient()
	var sphere := SphereShape3D.new()
	sphere.radius = collision_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.collision_mask = 1
	query.exclude = excluded
	var steps := maxi(1, ceili(length / (collision_radius * 1.5)))
	var step := displacement / float(steps)
	var space := get_world_3d().direct_space_state
	for i in steps:
		var next := global_position + step
		var ray := PhysicsRayQueryParameters3D.create(global_position, next, 1, excluded)
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			_impact(hit["collider"])
			return
		query.transform = Transform3D(Basis.IDENTITY, next)
		for overlap in space.intersect_shape(query, 8):
			_impact(overlap["collider"])
			return
		global_position = next
	distance_travelled += length
	if distance_travelled >= max_distance:
		queue_free()
func _impact(body: Object) -> void:
	if body == player:
		player.receive_damage(damage, source_position)
	queue_free()
func _orient() -> void:
	if velocity.length_squared() > 0.001:
		var up := Vector3.RIGHT if absf(velocity.normalized().y) > 0.98 else Vector3.UP
		look_at(global_position + velocity, up)
func _create_trail() -> void:
	var trail := CPUParticles3D.new()
	trail.amount = 12
	trail.lifetime = 0.16
	trail.local_coords = false
	trail.direction = Vector3(0,0,1)
	trail.spread = 14.0
	trail.initial_velocity_min = 0.3
	trail.initial_velocity_max = 1.0
	trail.gravity = Vector3.ZERO
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1,0.50,0.1,0.6) if kind == "fireball" else Color(1,0.85,0.5,0.35))
	gradient.set_color(1, Color(1,0.15,0.02,0.0))
	trail.color_ramp = gradient
	var mesh := SphereMesh.new()
	mesh.radius = 0.08 if kind == "fireball" else 0.025
	mesh.height = mesh.radius * 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	trail.mesh = mesh
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail)
