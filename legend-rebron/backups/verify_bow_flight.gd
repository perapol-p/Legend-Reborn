extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.3).timeout
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	combat.equip("bow")
	await create_timer(0.1).timeout
	assert(combat.view.nocked_arrow.visible)
	combat.cooldown = 0.0
	assert(combat.try_attack())
	assert(combat.view.nocked_arrow.visible)
	await create_timer(0.25).timeout
	assert(not combat.view.nocked_arrow.visible)
	assert(combat.projectiles_fired > 0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/bow_arrow_released.png")
	await create_timer(0.65).timeout
	assert(combat.view.nocked_arrow.visible)
	combat.bow_ammo = 1
	combat.cooldown = 0.0
	assert(combat.try_attack())
	await create_timer(0.9).timeout
	assert(combat.bow_reload > 0.0)
	assert(not combat.view.nocked_arrow.visible)
	await create_timer(0.75).timeout
	assert(combat.view.nocked_arrow.visible)
	var shot = load("res://scripts/weapon_projectile.gd").new()
	shot.direction = Vector3.FORWARD
	shot.speed = 38.0
	game.add_child(shot)
	shot.global_position = Vector3(0, 30, 0)
	var initial_position = shot.global_position
	await create_timer(0.5).timeout
	assert(is_instance_valid(shot))
	assert(shot.global_position.y < initial_position.y - 0.5)
	assert(shot.velocity.y < -3.0)
	assert(shot.wind_rings.size() == 3)
	assert(shot.get_node("WindTrail").emitting)
	assert((-shot.global_basis.z).dot(shot.velocity.normalized()) > 0.99)
	print("PASS nocked arrow release, re-nock, reload; gravity, velocity orientation, wind effects")
	quit()
