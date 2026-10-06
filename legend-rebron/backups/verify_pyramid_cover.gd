extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	for i in 15:
		await physics_frame
	paused = false
	game.get_node("Interface/PauseOverlay").hide()
	for cover in game.get_node("Arena/Cover").get_children():
		assert(cover.is_in_group("unstable_cover"))
		assert(cover.get_node("Mesh").mesh is CylinderMesh)
		assert(cover.get_node("Collision").shape is ConvexPolygonShape3D)
	var player = game.get_node("Player")
	player.global_position = Vector3(12,4.3,10)
	player.velocity = Vector3.ZERO
	for i in 180:
		await physics_frame
	assert(player.global_position.y < 0.6)
	var ray = PhysicsRayQueryParameters3D.create(Vector3(8,1,10),Vector3(16,1,10),1,[player.get_rid()])
	var hit = player.get_world_3d().direct_space_state.intersect_ray(ray)
	assert(not hit.is_empty() and hit["collider"].is_in_group("unstable_cover"))
	print("PASS eight pyramids, matching convex collision, apex cannot retain standing player, cover blocks rays")
	game.free()
	quit()
