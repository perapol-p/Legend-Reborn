extends RefCounted
## Ignore enemy bodies while keeping walls and the player in the ray.
static func ray_hit(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, excluded: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, excluded)
	while true:
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return hit
		var body = hit["collider"]
		if body is Node and body.is_in_group("monsters"):
			var rid: RID = hit["rid"]
			if excluded.has(rid):
				return {}
			excluded.append(rid)
			query.exclude = excluded
		else:
			return hit
	return {}
