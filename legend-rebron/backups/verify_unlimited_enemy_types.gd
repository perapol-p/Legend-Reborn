extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	var spawner = game.get_node("MonsterSpawner")
	spawner.enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.2).timeout
	paused = false
	spawner.set_physics_process(false)
	spawner.survival_time = 600.0
	for type in ["archer_monster", "flying_monster"]:
		for i in 20:
			var monster = load("res://scenes/" + type + ".tscn").instantiate()
			monster.player = game.get_node("Player")
			monster.position = Vector3(100+i*3,10,100)
			game.add_child(monster)
			monster.set_physics_process(false)
			spawner.monsters.append(monster)
	assert(spawner.monster_spawn_weights() == {"melee":74.0,"archer":18.0,"flyer":8.0})
	var counts := {"melee":0,"archer":0,"flyer":0}
	for i in 5000:
		counts[spawner.pick_monster_type()] += 1
	assert(counts["archer"] > 0 and counts["flyer"] > 0)
	spawner.survival_time = 299.0
	assert(spawner.monster_spawn_weights()["archer"] == 0.0)
	spawner.survival_time = 599.0
	assert(spawner.monster_spawn_weights()["flyer"] == 0.0)
	print("PASS both ranged types still spawn above former caps; unlock times retained; sample=",counts)
	game.free()
	quit()
