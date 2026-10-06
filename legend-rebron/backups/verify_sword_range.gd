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
	var run = game.get_node("RunState")
	combat.equip("sword")
	for level in range(2, 6):
		run.weapon_levels["sword"] = level
		var distance: float = [6.0, 12.0, 20.0, 32.0][level - 2]
		var targets: Array[Node3D] = []
		for z in [2.0, 4.0, distance + 3.0]:
			var target = load("res://scenes/training_dummy.tscn").instantiate()
			target.max_health = 10000.0
			game.add_child(target)
			target.global_position = combat.player.global_position + Vector3(0, 0, -z)
			targets.append(target)
		await physics_frame
		await physics_frame
		combat.resolve_attack()
		var shot = get_nodes_in_group("weapon_projectiles")[0]
		assert(shot.piercing)
		assert(is_equal_approx(shot.travel_remaining, distance))
		shot.set_physics_process(false)
		var start: Vector3 = shot.global_position
		# One large step must stop precisely at the range limit and pierce both targets.
		shot._physics_process(3.0)
		assert(shot.is_queued_for_deletion())
		assert(is_equal_approx(shot.global_position.distance_to(start), distance))
		assert(targets[0].health < 10000 and targets[1].health < 10000)
		assert(targets[2].health == 10000)
		print("PASS sword LV",level," pierces two targets; range=",distance," m; beyond-range target unharmed")
		for target in targets:
			target.free()
		await process_frame
	quit()
