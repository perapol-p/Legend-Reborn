extends Node3D
const HALF_EXTENT := 80.0
func is_spawn_point_inside(point: Vector3) -> bool:
	var local := to_local(point)
	return absf(local.x) <= HALF_EXTENT - 3.0 and absf(local.z) <= HALF_EXTENT - 3.0
func movement_target(actor: Node3D, target: Vector3) -> Vector3:
	var destination := to_local(target)
	var current := to_local(actor.global_position)
	# Approach raised areas through their ramps, rather than the vertical faces.
	if destination.y > 1.4 and destination.x >= 16 and destination.x <= 36 and absf(destination.z) <= 12 and current.y < 1.5:
		return to_global(Vector3(18,2,0) if current.x >= 4 and current.x <= 18 and absf(current.z) < 3.2 else Vector3(4,0,0))
	if destination.y > 2.4 and destination.x >= -35 and destination.x <= -17 and destination.z >= -33 and destination.z <= -15 and current.y < 2.5:
		return to_global(Vector3(-26,3,-17) if current.z <= -3 and current.z >= -17 and absf(current.x+26) < 3.2 else Vector3(-26,0,-3))
	if destination.y > 0.65 and destination.x >= 18 and destination.x <= 30 and destination.z >= -42 and destination.z <= -30 and current.y < 0.7:
		return to_global(Vector3(24,1,-32) if current.z <= -22 and current.z >= -32 and absf(current.x-24) < 3.2 else Vector3(24,0,-22))
	return target
func steer_direction(actor: CharacterBody3D, desired: Vector3) -> Vector3:
	if desired.length_squared() < 0.001:
		return desired
	var space := get_world_3d().direct_space_state
	var origin := actor.global_position + Vector3.UP * 0.85
	for angle in [0.0,0.65,-0.65,1.15,-1.15,1.57,-1.57]:
		var candidate := desired.rotated(Vector3.UP,angle)
		var excluded: Array[RID] = [actor.get_rid(),actor.player.get_rid()]
		var hit := preload("res://scripts/enemy_targeting.gd").ray_hit(space,origin,origin+candidate*2.0,excluded)
		if hit.is_empty() or Vector3(hit["normal"]).y > 0.7 or "Ramp" in str(hit["collider"].name):
			return candidate
	return Vector3.ZERO
