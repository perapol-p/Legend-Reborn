extends "res://scripts/monster.gd"
const PROJECTILE = preload("res://scripts/enemy_projectile.gd")
@export var enemy_type := "archer"
@export var preferred_distance := 11.0
@export var retreat_distance := 6.0
@export var windup_duration := 0.55
@export var projectile_speed := 16.0
@export var hover_height := 2.2
var windup_remaining := -1.0
var locked_target := Vector3.ZERO
var hover_time := 0.0
var shots_fired := 0
var muzzle: Marker3D
var charge_visual: MeshInstance3D
var wings: Array[MeshInstance3D] = []
func _ready() -> void:
	super._ready()
	add_to_group("archer_monsters" if enemy_type == "archer" else "flying_monsters")
	attack_timer = randf_range(1.0, 2.0)
	var skin := _material(Color("ac853d") if enemy_type == "archer" else Color("6b3b94"))
	for mesh in $Model.find_children("*", "MeshInstance3D", true, false):
		if not "Eye" in mesh.name:
			mesh.material_override = skin
	muzzle = Marker3D.new()
	$Model.add_child(muzzle)
	muzzle.position = Vector3(0.45, 1.35, -0.8) if enemy_type == "archer" else Vector3(0, 1.4, -0.55)
	charge_visual = MeshInstance3D.new()
	var glow := SphereMesh.new()
	glow.radius = 0.12
	glow.height = 0.24
	charge_visual.mesh = glow
	charge_visual.material_override = _material(Color("fff097") if enemy_type == "archer" else Color("ff650d"), true)
	muzzle.add_child(charge_visual)
	charge_visual.hide()
	if enemy_type == "archer":
		_build_bow()
	else:
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		_build_wings()
func refresh() -> void:
	health_label.text = ("ARCHER " if enemy_type == "archer" else "FIRE WISP ") + "%d / %d" % [ceili(health), ceili(max_health)]
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player) or player.run.finished:
		return
	hit_flash = maxf(0.0, hit_flash - delta)
	if hit_flash == 0.0:
		model.scale = Vector3.ONE
	attack_timer = maxf(0.0, attack_timer - delta)
	hover_time += delta
	var offset := player.global_position - global_position
	var flat := Vector3(offset.x, 0, offset.z)
	var distance := flat.length()
	var direction := flat.normalized()
	if distance > 0.05:
		rotation.y = atan2(-direction.x, -direction.z)
	var movement := 1.0 if distance > preferred_distance else (-0.65 if distance < retreat_distance else 0.0)
	if windup_remaining >= 0.0:
		movement = 0.0
	velocity.x = direction.x * move_speed * movement
	velocity.z = direction.z * move_speed * movement
	if enemy_type == "flyer":
		var altitude := player.global_position.y + hover_height + sin(hover_time * 2.0) * 0.18
		velocity.y = clampf((altitude - global_position.y) * 2.5, -3.0, 3.0)
		for i in wings.size():
			wings[i].rotation.z = (1.0 if i == 0 else -1.0) * (0.15 + sin(hover_time * 8.0) * 0.35)
	else:
		velocity.y -= 25.0 * delta
	move_and_slide()
	if global_position.y < -25.0:
		queue_free()
		return
	if windup_remaining >= 0.0:
		windup_remaining -= delta
		charge_visual.scale = Vector3.ONE * (1.0 + 0.30 * sin(hover_time * 24.0))
		if windup_remaining <= 0.0:
			windup_remaining = -1.0
			charge_visual.hide()
			if can_fire():
				_fire_projectile()
			attack_timer = attack_interval + randf_range(0.0, 0.4)
	elif attack_timer <= 0.0 and can_fire():
		locked_target = player.global_position + Vector3(0, 1.0, 0)
		windup_remaining = windup_duration
		charge_visual.show()
func can_fire() -> bool:
	var target := player.global_position + Vector3(0,1.0,0)
	if muzzle.global_position.distance_to(target) > attack_range:
		return false
	var query := PhysicsRayQueryParameters3D.create(muzzle.global_position, target, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit["collider"] == player
func _fire_projectile() -> void:
	var shot = PROJECTILE.new()
	shot.player = player
	shot.kind = "arrow" if enemy_type == "archer" else "fireball"
	shot.damage = attack_damage
	shot.gravity = 3.0 if enemy_type == "archer" else 0.0
	shot.max_distance = 32.0 if enemy_type == "archer" else 10.0
	shot.remaining = 3.0 if enemy_type == "archer" else 1.2
	shot.source_position = global_position
	shot.excluded.assign([get_rid()])
	var aim := locked_target - muzzle.global_position
	var time := aim.length() / projectile_speed
	aim.y += 0.5 * shot.gravity * time * time
	shot.velocity = aim.normalized() * projectile_speed
	var world := get_parent()
	shot.position = world.to_local(muzzle.global_position)
	world.add_child(shot)
	shots_fired += 1
func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
func _build_bow() -> void:
	var bow := Node3D.new()
	bow.position = Vector3(0.45, 1.30, -0.50)
	$Model.add_child(bow)
	var material := _material(Color("603619"))
	for side in [-1.0, 1.0]:
		var limb := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.07, 0.47, 0.07)
		limb.mesh = mesh
		limb.position.y = side * 0.25
		limb.rotation.x = side * 0.32
		limb.material_override = material
		bow.add_child(limb)
	var string := MeshInstance3D.new()
	var string_mesh := BoxMesh.new()
	string_mesh.size = Vector3(0.012, 0.92, 0.012)
	string.mesh = string_mesh
	string.position.z = 0.09
	string.material_override = _material(Color("e9dbb3"))
	bow.add_child(string)
	$Model/RightArm.rotation.x = -1.2
	$Model/LeftArm.rotation.x = -1.1
func _build_wings() -> void:
	for part in ["LeftLeg", "RightLeg", "LeftArm", "RightArm"]:
		get_node("Model/" + part).hide()
	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(1.1, 0.12, 0.55)
		wing.mesh = mesh
		wing.position = Vector3(side * 0.75, 1.25, 0)
		wing.material_override = _material(Color("41295c"))
		$Model.add_child(wing)
		wings.append(wing)

