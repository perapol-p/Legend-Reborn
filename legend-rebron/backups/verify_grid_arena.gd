extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await frames(16)
	paused = false
	game.get_node("Interface/PauseOverlay").hide()
	var player = game.get_node("Player")
	var arena = game.get_node("Arena")
	assert(arena.get_node("Boundaries").get_child_count() == 4)
	assert(arena.get_node("Cover").get_child_count() == 8)
	assert(arena.get_node("Floor/Mesh").mesh.material is ShaderMaterial)
	for sample in [[Vector3(26,8,0),2.0],[Vector3(-26,8,-24),3.0],[Vector3(24,8,-36),1.0]]:
		var ray = PhysicsRayQueryParameters3D.create(sample[0],sample[0]-Vector3.UP*10.0)
		var hit = player.get_world_3d().direct_space_state.intersect_ray(ray)
		assert(not hit.is_empty() and absf(hit["position"].y-sample[1]) < 0.02)
	player.respawn()
	player.global_position = Vector3(4,0.08,0)
	Input.action_press("move_right")
	await frames(130)
	Input.action_release("move_right")
	assert(player.global_position.x > 18 and player.global_position.y > 1.8)
	print("PASS player climbs ramp to raised terrain")
	player.respawn()
	player.global_position = Vector3(77,0.08,30)
	Input.action_press("move_right")
	await frames(80)
	Input.action_release("move_right")
	assert(player.global_position.x < 79.0)
	player.respawn()
	player.global_position = Vector3(8,0.08,10)
	Input.action_press("move_right")
	await frames(50)
	Input.action_release("move_right")
	assert(player.global_position.x < 10.0)
	print("PASS boundary and box collision")
	player.respawn()
	player.global_position = Vector3(26,2.05,0)
	var enemy = load("res://scenes/monster.tscn").instantiate()
	enemy.player = player
	enemy.position = Vector3(4,0.08,0)
	enemy.attack_timer = 1000.0
	game.add_child(enemy)
	await frames(650)
	assert(enemy.global_position.x > 20 and enemy.global_position.y > 1.8)
	enemy.free()
	print("PASS melee monster follows player via ramp")
	player.respawn()
	var spawner = game.get_node("MonsterSpawner")
	spawner.enabled = true
	spawner.set_physics_process(false)
	for position in [Vector3.ZERO,Vector3(76,0,0),Vector3(0,0,76),Vector3(-76,0,-76)]:
		player.global_position = position + Vector3.UP * 0.08
		await frames(2)
		for i in 8:
			var monster = spawner.spawn_one()
			assert(monster != null)
			assert(arena.is_spawn_point_inside(monster.global_position))
			monster.queue_free()
			await process_frame
	print("PASS spawns stay inside arena including near corners")
	player.respawn()
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/grid_arena_fps.png")
	player.get_node("Head/Camera3D/Combat").view.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.position = Vector3(0,52,62)
	camera.fov = 85
	camera.look_at(Vector3(0,0,-10),Vector3.UP)
	camera.current = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/grid_arena_overview.png")
	print("PASS grid shader rendering, walls, platforms, ramps, boxes and spawning")
	game.free()
	quit()
