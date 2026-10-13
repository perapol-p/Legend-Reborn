extends Node3D
var source: Node
var damage := 4.0
var critical := false
var source_weapon := ""
var radius := 3.0
var remaining := 2.0
var pulse := 0.0
var model: Node3D
var scan_remaining := 0.0
var cached_bodies: Array = []
func _ready() -> void:
	add_to_group("weapon_tornadoes")
	model = preload("res://scripts/magic_vortex_vfx.gd").new()
	model.radius = radius
	add_child(model)
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
	scan_remaining -= delta
	if tick or scan_remaining <= 0.0:
		cached_bodies = source.damageables(global_position,radius)
		scan_remaining = 0.1
	for body in cached_bodies:
		if not is_instance_valid(body) or body.is_queued_for_deletion(): continue
		if body is CharacterBody3D and not body.is_queued_for_deletion():
			var offset: Vector3 = global_position - body.global_position
			offset.y = 0.0
			if offset.length() > 0.3:
				body.move_and_collide(offset.normalized() * minf(offset.length(), 5.0 * delta))
		if tick:
			source.deal_hit(body, damage, source_weapon, false, critical)

