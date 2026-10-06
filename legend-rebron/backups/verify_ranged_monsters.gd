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
	var spawner = game.get_node("MonsterSpawner")
	spawner.set_physics_process(false)
	spawner.enabled = true
	spawner.rng.seed = 4351
	for seconds in [299.99, 300.0, 599.99, 600.0]:
		spawner.survival_time = seconds
		var counts := {"melee":0,"archer":0,"flyer":0}
		for i in 5000:
			counts[spawner.pick_monster_type()] += 1
		assert(counts["archer"] == 0 if seconds < 300.0 else counts["archer"] > 700)
		assert(counts["flyer"] == 0 if seconds < 600.0 else counts["flyer"] > 250)
		print("PASS spawn unlock ", seconds, "s sample5000=",counts)
	spawner.survival_time = 600.0
	var archer = load("res://scenes/archer_monster.tscn").instantiate()
	archer.player = game.get_node("Player")
	archer.position = archer.player.global_position + Vector3(0,0.06,-12)
	game.add_child(archer)
	var flyer = load("res://scenes/flying_monster.tscn").instantiate()
	flyer.player = archer.player
	flyer.position = archer.player.global_position + Vector3(2,2.2,-4.5)
	game.add_child(flyer)
	spawner.monsters.assign([archer,flyer])
	spawner.max_archers = 1
	spawner.max_flyers = 1
	var weights = spawner.monster_spawn_weights()
	assert(weights["archer"] == 0 and weights["flyer"] == 0)
	for i in 100:
		assert(spawner.pick_monster_type() == "melee")
	spawner.monsters.clear()
	archer.attack_timer = 0.0
	flyer.attack_timer = 0.0
	await create_timer(0.15).timeout
	assert(archer.windup_remaining > 0.0 and archer.shots_fired == 0)
	assert(flyer.windup_remaining > 0.0 and flyer.shots_fired == 0)
	var hp: float = archer.player.run.current_health()
	await create_timer(1.2).timeout
	assert(archer.shots_fired >= 1 and flyer.shots_fired >= 1)
	assert(archer.player.run.current_health() < hp)
	assert(game.damage_feedback.hits.size() > 0)
	assert(flyer.global_position.y > flyer.player.global_position.y + 1.7)
	var before: int = flyer.shots_fired
	flyer.global_position = flyer.player.global_position + Vector3(0,2.2,-14)
	flyer.attack_timer = 0.0
	await create_timer(0.9).timeout
	assert(flyer.shots_fired == before)
	print("PASS caps fallback, telegraphs before firing, real projectile damage/direction, flight altitude and short fireball range")
	archer.free()
	flyer.free()
	for shot in get_nodes_in_group("enemy_projectiles"):
		shot.queue_free()
	game.free()
	quit()






