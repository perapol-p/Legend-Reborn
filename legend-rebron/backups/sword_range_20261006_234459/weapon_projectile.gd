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
var velocity := Vector3.ZERO
var flight_time := 0.0
var wave_vfx: Node3D
var wind_rings: Array[MeshInstance3D] = []
const ARROW_GRAVITY := 8.0
const ARROW_DRAG := 0.10
func _ready() -> void:
	add_to_group("weapon_projectiles")
	var visual := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	if kind == "bow":
		velocity = direction.normalized() * speed
		var arrow := CylinderMesh.new()
		arrow.top_radius = 0.025
		arrow.bottom_radius = 0.025
		arrow.height = 0.95
		visual.mesh = arrow
		visual.rotation.x = PI / 2
		material.albedo_color = Color(0.92, 0.64, 0.27)
		var tip := MeshInstance3D.new()
		var tip_mesh := CylinderMesh.new()
		tip_mesh.top_radius = 0.0
		tip_mesh.bottom_radius = 0.075
		tip_mesh.height = 0.20
		tip.mesh = tip_mesh
		tip.rotation.x = -PI / 2
		tip.position.z = -0.55
		tip.material_override = _arrow_material(Color(0.82, 0.94, 1.0))
		add_child(tip)
		for i in 3:
			var feather := MeshInstance3D.new()
			var feather_mesh := BoxMesh.new()
			feather_mesh.size = Vector3(0.012, 0.14, 0.22)
			feather.mesh = feather_mesh
			feather.position.z = 0.35
			feather.rotation.z = float(i) * TAU / 3.0
			feather.material_override = _arrow_material(Color(0.90, 0.98, 1.0))
			add_child(feather)
		_create_wind()
	elif kind == "sword_wave":
		var wave := preload("res://scripts/sword_wave_vfx.gd").new()
		wave.name = "SwordWaveVFX"
		wave.radius = maxf(hit_radius * 2.2, 1.25)
		add_child(wave)
		wave_vfx = wave
		visual.free()
		return
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
	if kind == "sword_wave":
		_advance_sword_wave(displacement)
		return
	if kind == "bow":
		flight_time += delta
		var previous_velocity := velocity
		velocity *= exp(-ARROW_DRAG * delta)
		velocity.y -= ARROW_GRAVITY * delta
		displacement = (previous_velocity + velocity) * 0.5 * delta
		direction = velocity.normalized()
		var up := Vector3.UP if absf(direction.y) < 0.98 else Vector3.RIGHT
		look_at(global_position + direction, up)
		for i in wind_rings.size():
			var ring := wind_rings[i]
			var phase := fposmod(flight_time * 3.5 + float(i) * 0.33, 1.0)
			ring.position.z = 0.10 + phase * 0.95
			ring.scale = Vector3.ONE * (0.45 + phase * 0.75)
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

func _arrow_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _create_wind() -> void:
	var wind_material := _arrow_material(Color(0.68, 0.92, 1.0, 0.32))
	wind_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 3:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.095
		torus.outer_radius = 0.108
		torus.rings = 16
		torus.ring_segments = 6
		ring.mesh = torus
		ring.rotation.x = PI / 2
		ring.material_override = wind_material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		wind_rings.append(ring)
	var trail := CPUParticles3D.new()
	trail.name = "WindTrail"
	trail.amount = 24
	trail.lifetime = 0.18
	trail.local_coords = false
	trail.direction = Vector3(0, 0, 1)
	trail.spread = 8.0
	trail.initial_velocity_min = 0.5
	trail.initial_velocity_max = 1.5
	trail.gravity = Vector3.ZERO
	trail.scale_amount_min = 0.65
	trail.scale_amount_max = 1.0
	var fade := Gradient.new()
	fade.set_color(0, Color(0.72, 0.94, 1.0, 0.55))
	fade.set_color(1, Color(0.72, 0.94, 1.0, 0.0))
	trail.color_ramp = fade
	var streak := BoxMesh.new()
	streak.size = Vector3(0.018, 0.018, 0.22)
	var trail_material := _arrow_material(Color.WHITE)
	trail_material.vertex_color_use_as_albedo = true
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.material = trail_material
	trail.mesh = streak
	trail.position.z = 0.45
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail)




func _advance_sword_wave(displacement: Vector3) -> void:
	wave_vfx.sync_collision_transform()
	var space := get_world_3d().direct_space_state
	var contacts: Array[Dictionary] = []
	for piece in wave_vfx.hit_shapes:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = piece["shape"]
		query.transform = wave_vfx.global_transform * piece["offset"]
		query.collision_mask = 1
		query.exclude = excluded + struck
		query.margin = 0.002
		# Include initial overlaps and sweep the whole movement to prevent tunneling.
		for hit in space.intersect_shape(query, 32):
			contacts.append({"body": hit["collider"], "fraction": 0.0})
		var starting_transform := query.transform
		# Piercing can cross more than one body within a single physics frame.
		for sweep_index in 32:
			query.transform = starting_transform
			query.motion = displacement
			var fractions := space.cast_motion(query)
			if fractions[0] >= 1.0:
				break
			query.transform.origin += displacement * minf(fractions[1] + 0.001, 1.0)
			query.motion = Vector3.ZERO
			var hits := space.intersect_shape(query, 32)
			var continue_sweep := piercing and not hits.is_empty()
			var next_exclusions := query.exclude
			for hit in hits:
				contacts.append({"body": hit["collider"], "fraction": fractions[0]})
				next_exclusions.append(hit["rid"])
				if not hit["collider"].has_method("take_damage"):
					continue_sweep = false
			query.exclude = next_exclusions
			if not continue_sweep:
				break
	# Resolve the nearest contact first, including walls reached by the outer tips.
	contacts.sort_custom(func(a: Dictionary, b: Dictionary): return a["fraction"] < b["fraction"])
	for contact in contacts:
		var body = contact["body"]
		if is_instance_valid(body) and not struck.has(body.get_rid()):
			var point := global_position + displacement * float(contact["fraction"])
			if impact(body, point):
				global_position = point
				return
	global_position += displacement

