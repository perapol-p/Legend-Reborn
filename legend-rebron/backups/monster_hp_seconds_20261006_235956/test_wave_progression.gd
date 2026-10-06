extends Node
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	var spawner = game.get_node("MonsterSpawner")
	spawner.enabled = false
	add_child(game)
	await get_tree().physics_frame
	spawner.set_physics_process(false)
	spawner.enabled = true
	var hud = game.get_node("Interface/HUD")
	for seconds in [0.0, 9.99, 10.0, 20.0, 50.0]:
		spawner.survival_time = seconds
		spawner.countdown = 1000.0
		spawner._physics_process(0.0)
		var step := int(seconds / 10.0)
		check(spawner.spawn_batch_size() == 1 + step, "Spawn batch increases every 10 seconds")
		var monster = spawner.spawn_one()
		check(monster != null, "Spawn succeeds")
		if monster != null:
			check(is_equal_approx(monster.max_health, 30.0 + step * 5.0), "HP scales with time")
			check(monster.health == monster.max_health, "New monster starts at full HP")
			check(monster.attack_damage == 8.0 and monster.move_speed == 2.6, "Difficulty increases via health")
			monster.queue_free()
		await get_tree().process_frame
	spawner.reset_encounter()
	check(spawner.survival_time == 0 and spawner.spawn_batch_size() == 1, "Death reset clears difficulty")
	spawner.countdown = 0.0
	spawner._physics_process(0.0)
	check(spawner.monsters.size() == 4, "Initial four monsters")
	var before: float = spawner.survival_time
	get_tree().paused = true
	spawner._physics_process(10.0)
	check(spawner.survival_time == before, "Pause freezes difficulty")
	get_tree().paused = false
	for monster in spawner.monsters:
		monster.queue_free()
	await get_tree().process_frame
	spawner.survival_time = 20.0
	spawner.countdown = 0.0
	spawner._physics_process(0.0)
	check(spawner.monsters.size() == 3, "Continuous spawn batch at 20 seconds without waiting for clear")
	hud.refresh_survival()
	check(not hud.survival_label.text.contains("WAVE"), "HUD removes waves")
	spawner.max_alive = 3
	spawner.countdown = 0.0
	spawner._physics_process(0.0)
	check(spawner.monsters.size() == 3, "Alive cap respected")
	print("SURVIVAL SPAWNING ", "FAILED" if failed else "PASSED")
	get_tree().quit(1 if failed else 0)
