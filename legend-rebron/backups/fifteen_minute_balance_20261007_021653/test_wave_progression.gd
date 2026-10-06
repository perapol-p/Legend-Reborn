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
	for seconds in [0.0, 89.99, 90.0, 180.0, 900.0]:
		spawner.survival_time = seconds
		spawner.countdown = 1000.0
		spawner._physics_process(0.0)
		var step := int(seconds / 90.0)
		check(spawner.spawn_batch_size() == mini(2 + step, 12), "Spawn batch increases every 90 seconds")
		var monster = spawner.spawn_one()
		check(monster != null, "Spawn succeeds")
		if monster != null:
			var minutes: float = floor(float(seconds)) / 60.0
			var multiplier := 0.7 if monster.is_in_group("archer_monsters") else (0.6 if monster.is_in_group("flying_monsters") else 1.0)
			check(is_equal_approx(monster.max_health, (40.0 + 30.0 * minutes + 6.0 * minutes * minutes) * multiplier), "HP follows time curve and enemy role")
			check(monster.health == monster.max_health, "New monster starts at full HP")
			if multiplier == 1.0:
				check(monster.attack_damage == 8.0 and monster.move_speed == 2.6, "Melee defaults unchanged")
			monster.queue_free()
		await get_tree().process_frame
	for sample in [[0.0, 40.0], [0.99, 40.0], [1.0, 40.5016666667], [60.0, 76.0], [180.0, 184.0], [300.0, 340.0], [600.0, 940.0]]:
		spawner.survival_time = sample[0]
		check(absf(spawner.monster_health() - sample[1]) < 0.00001, "HP curve checkpoint " + str(sample[0]))
	spawner.survival_time = 5.0
	var health_before: float = spawner.monster_health()
	spawner.survival_time = 6.0
	check(spawner.monster_health() > health_before, "HP growth is independent from the spawn interval")
	spawner.reset_encounter()
	check(spawner.survival_time == 0 and spawner.spawn_batch_size() == 2, "Death reset clears difficulty")
	spawner.countdown = 0.0
	spawner._physics_process(0.0)
	check(spawner.monsters.size() == 6, "Initial six monsters")
	var before: float = spawner.survival_time
	get_tree().paused = true
	spawner._physics_process(10.0)
	check(spawner.survival_time == before, "Pause freezes difficulty")
	get_tree().paused = false
	for monster in spawner.monsters:
		monster.queue_free()
	await get_tree().process_frame
	spawner.survival_time = 180.0
	spawner.countdown = 0.0
	spawner._physics_process(0.0)
	check(spawner.monsters.size() == 4, "Continuous spawn batch at 180 seconds without waiting for clear")
	hud.refresh_survival()
	check(not hud.survival_label.text.contains("WAVE"), "HUD removes waves")
	spawner.countdown = 0.0
	spawner._physics_process(0.0)
	check(spawner.monsters.size() == 8, "Spawning continues while existing monsters are alive")
	for i in range(5):
		spawner.countdown = 0.0
		spawner._physics_process(0.0)
	check(spawner.monsters.size() > 16, "Population can exceed 16")
	check(spawner.spawn_one() != null, "Spawns continue without a population cap")
	print("SURVIVAL SPAWNING ", "FAILED" if failed else "PASSED")
	get_tree().quit(1 if failed else 0)







