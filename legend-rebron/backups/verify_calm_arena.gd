extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.2).timeout
	game.get_node("Interface/PauseOverlay").hide()
	paused = false
	var player = game.get_node("Player")
	assert(player.is_on_floor())
	player.dash_direction = Vector3.FORWARD
	player.dash_remaining = 0.15
	await create_timer(0.1).timeout
	assert(is_equal_approx(player.camera.fov,90.0))
	player.respawn()
	var combat = player.get_node("Head/Camera3D/Combat")
	combat.equip("sword")
	var spawner = game.get_node("MonsterSpawner")
	spawner.enabled = true
	spawner.countdown = 1000.0
	for i in 6:
		var monster = spawner.spawn_one()
		assert(monster != null)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/calm_arena_preview.png")
	var material = game.get_node("Arena/Floor/Mesh").mesh.material
	assert(material.roughness == 1.0 and material.albedo_color.r < 0.5)
	print("PASS matte calm arena, constant dash FOV, floor collision and spawning")
	game.free()
	quit()
