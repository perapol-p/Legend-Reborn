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
	await frames(15)
	paused = false
	game.get_node("Interface/PauseOverlay").hide()
	var player = game.get_node("Player")
	Input.action_press("move_right")
	await frames(18)
	assert(player.head.rotation.z < -0.01)
	assert(absf(player.head.rotation.z) <= deg_to_rad(1.5) + 0.001)
	assert(player.head.position.x > 0.0)
	var walking: float = absf(player.head.rotation.z)
	Input.action_press("dash")
	await frames(6)
	Input.action_release("dash")
	assert(absf(player.head.rotation.z) > walking)
	assert(absf(player.head.rotation.z) <= deg_to_rad(4.0) + 0.001)
	assert(player.camera.fov == 90.0)
	Input.action_release("move_right")
	await frames(45)
	assert(absf(player.head.rotation.z) < 0.001 and absf(player.head.position.x) < 0.001)
	player.respawn()
	Input.action_press("move_left")
	await frames(18)
	assert(player.head.rotation.z > 0.01 and player.head.position.x < 0.0)
	Input.action_release("move_left")
	player.respawn()
	assert(player.head.rotation.z == 0.0 and player.head.position == player.head_rest_position)
	print("PASS left/right lean, stronger side-dash lean, bounded angles, smooth recovery, fixed FOV and respawn reset")
	game.free()
	quit()
