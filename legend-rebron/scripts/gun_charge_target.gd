extends StaticBody3D
const LIFETIME := 3.0
var source: Node
var remaining := LIFETIME
var collected := false
func _ready() -> void:
	add_to_group("gun_charge_targets")
	collision_layer = 2
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	collider.shape = sphere
	add_child(collider)
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.48
	mesh.height = 0.96
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ff293e")
	material.emission_enabled = true
	material.emission = Color("ff152e")
	material.emission_energy_multiplier = 2.0
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.54
	ring_mesh.outer_radius = 0.62
	ring.mesh = ring_mesh
	ring.rotation.x = PI / 2
	ring.material_override = material
	add_child(ring)
func _physics_process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.0 or not is_instance_valid(source):
		collision_layer = 0
		queue_free()
		return
	scale = Vector3.ONE * maxf(0.01, remaining / LIFETIME)
	if is_instance_valid(source.camera):
		look_at(source.camera.global_position, Vector3.UP)
func collect_charge(shooter: Node) -> bool:
	if collected or remaining <= 0.0 or shooter != source or not shooter.can_act() or shooter.weapon_id != "gun" or shooter.weapon_level() < 3:
		return false
	collected = true
	collision_layer = 0
	shooter.unlock_charge()
	hide()
	queue_free()
	return true