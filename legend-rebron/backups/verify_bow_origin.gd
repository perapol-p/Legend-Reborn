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
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	combat.equip("bow")
	for turn in [0.0, 0.7]:
		combat.player.rotation.y = turn
		combat.view.play_attack(0.8)
		combat.view.animation_player.advance(0.2)
		var release: Vector3 = combat.view.arrow_release_position()
		var forward: Vector3 = -combat.camera.global_basis.z
		var target: Vector3 = combat.camera.global_position + forward * 120.0
		var bow_forward: Vector3 = (target - release).normalized()
		var expected: Vector3 = release + bow_forward * 0.45
		combat.bow_ammo = 4
		combat.resolve_attack()
		var arrows = get_nodes_in_group("weapon_projectiles")
		assert(arrows.size() == 2)
		for arrow in arrows:
			assert(arrow.global_position.distance_to(expected) < 0.001)
			assert(arrow.global_position.distance_to(combat.camera.global_position + forward * 0.15) > 0.15)
			assert(arrow.direction.dot(bow_forward) > 0.999)
		assert(not combat.view.nocked_arrow.visible)
		print("PASS animated bow origin, aim convergence, rotated camera; release=", release)
		for arrow in arrows:
			arrow.free()
	var camera_forward: Vector3 = -combat.camera.global_basis.z
	var other = combat.fire_projectile("magic_wave", camera_forward, 1.0, 22.0, 0.15, false)
	assert(other.global_position.distance_to(combat.camera.global_position + camera_forward * 0.15) < 0.001)
	print("PASS other projectile origins unchanged")
	quit()
