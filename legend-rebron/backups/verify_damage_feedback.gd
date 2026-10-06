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
	var feedback = game.damage_feedback
	feedback.set_process(false)
	var origin: Vector3 = player.global_position
	for sample in [[Vector3(0,0,-3),Vector2(0,-1)], [Vector3(0,0,3),Vector2(0,1)], [Vector3(3,0,0),Vector2(1,0)], [Vector3(-3,0,0),Vector2(-1,0)]]:
		assert(feedback.screen_direction(origin + sample[0]).is_equal_approx(sample[1]))
	var hp: float = player.run.current_health()
	player.receive_damage(20.0, origin + Vector3(0,0,3))
	assert(feedback.visible and feedback.hits.size() == 1)
	assert(player.run.current_health() == hp - 20)
	assert(feedback.vignette_material.get_shader_parameter("hit_direction").is_equal_approx(Vector2(0,1)))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/damage_from_behind.png")
	player.rotation.y = PI / 2
	assert(feedback.screen_direction(origin + Vector3(0,0,3)).is_equal_approx(Vector2(-1,0)))
	player.rotation.y = 0.0
	var before: int = feedback.hits.size()
	player.receive_damage(0.0, origin)
	assert(feedback.hits.size() == before)
	paused = true
	player.receive_damage(10.0, origin)
	assert(feedback.hits.size() == before)
	feedback._process(0.1)
	assert(not feedback.visible)
	paused = false
	feedback._process(0.9)
	assert(feedback.hits.is_empty() and not feedback.visible)
	player.receive_damage(1.0, origin + Vector3(3,0,0))
	player.receive_damage(1.0, origin + Vector3(-3,0,0))
	assert(feedback.hits.size() == 2)
	player.receive_damage(10000.0, origin + Vector3(0,0,3))
	feedback._process(0.0)
	assert(not feedback.visible)
	await process_frame
	await process_frame
	assert(game.result_overlay.visible)
	print("PASS front/back/left/right, camera-relative direction, damage event, red shader, fade, simultaneous hits, pause, zero damage and Game Over")
	game.free()
	quit()
