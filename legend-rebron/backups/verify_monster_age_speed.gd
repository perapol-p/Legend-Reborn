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
	paused = false
	var spawner = game.get_node("MonsterSpawner")
	spawner.set_physics_process(false)
	spawner.enabled = true
	spawner.rng.seed = 677
	for i in 125:
		var monster = spawner.spawn_one()
		if monster != null:
			monster.set_physics_process(false)
	assert(spawner.monsters.size() > 100)
	assert(spawner.spawn_one() != null)
	print("PASS unlimited total population: ",spawner.monsters.size())
	for path in ["monster", "archer_monster", "flying_monster", "boss"]:
		var actor = load("res://scenes/"+path+".tscn").instantiate()
		actor.player = game.get_node("Player")
		actor.position = Vector3(100,10,100)
		game.add_child(actor)
		actor.set_physics_process(false)
		var base: float = actor.move_speed
		assert(actor.alive_seconds == 0.0)
		actor.advance_age(60.0)
		assert(is_equal_approx(actor.move_speed,base*1.1))
		actor.advance_age(240.0)
		assert(is_equal_approx(actor.move_speed,base*1.5))
		paused = true
		actor.advance_age(600.0)
		assert(is_equal_approx(actor.move_speed,base*1.5))
		paused = false
		actor.advance_age(300.0)
		assert(is_equal_approx(actor.move_speed,base*2.0))
		print("PASS ",path," base=",base," 10min speed=",actor.move_speed," pause freezes age")
		actor.free()
	game.free()
	quit()
