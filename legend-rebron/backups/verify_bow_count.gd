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
	var run = game.get_node("RunState")
	var previous_span := 0.0
	for level in range(1, 6):
		run.weapon_levels["bow"] = level
		var first_directions: Array[Vector3] = []
		for volley in 2:
			for node in get_nodes_in_group("weapon_projectiles"):
				node.free()
			combat.bow_ammo = 4
			combat.bow_reload = 0.0
			combat.resolve_attack()
			var arrows = get_nodes_in_group("weapon_projectiles")
			assert(arrows.size() == [2, 4, 8, 16, 24][level - 1])
			var min_x := 1.0
			var max_x := -1.0
			for i in arrows.size():
				var local_direction: Vector3 = combat.camera.global_basis.inverse() * arrows[i].direction
				min_x = minf(min_x, local_direction.x)
				max_x = maxf(max_x, local_direction.x)
				assert(absf(local_direction.y) < 0.055)
				if volley == 0:
					first_directions.append(arrows[i].direction)
				else:
					assert(not arrows[i].direction.is_equal_approx(first_directions[i]))
			if volley == 0:
				var span := max_x - min_x
				assert(level == 1 or (span > previous_span if level <= 3 else span > 0.30))
				previous_span = span
			print("PASS bow spread LV",level," volley ",volley," count=",arrows.size()," width=",max_x-min_x)
	print("PASS increasing spread, bounded pitch jitter, unique volleys, all arrow counts")
	quit()


