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
		var targets: Array[Node3D] = []
		for distance in [4.0, 8.0]:
			var target = load("res://scenes/training_dummy.tscn").instantiate()
			target.max_health = 10000.0
			game.add_child(target)
			target.global_position = combat.player.global_position + Vector3(0, 0, -distance)
			targets.append(target)
		combat.resolve_attack()
		var shots = get_nodes_in_group("weapon_projectiles")
		assert(shots.size() == 1)
		assert(shots[0].piercing == (level == 5))
		await create_timer(0.7).timeout
		assert(targets[0].health < 10000.0)
		assert((targets[1].health < 10000.0) == (level == 5))
		print("PASS sword LV",level," first target hit; second target hit=",targets[1].health < 10000.0)
		for target in targets:
			target.free()
		for shot in get_nodes_in_group("weapon_projectiles"):
			shot.queue_free()
		await process_frame
	quit()
