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
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	var spawner = game.get_node("MonsterSpawner")
	spawner.max_alive = 2
	spawner.spawn_interval = 0.1
	spawner.wave_break = 0.1
	add_child(game)
	var hud = game.get_node("Interface/HUD")
	var counts := {1: 0, 2: 0, 3: 0}
	var stats := {}
	spawner.monster_spawned.connect(func(monster, _distance):
		var wave: int = spawner.wave_number
		if counts.has(wave):
			counts[wave] += 1
			stats[wave] = [monster.max_health, monster.attack_damage, monster.move_speed, monster.attack_interval]
	)
	await get_tree().physics_frame
	var before: float = spawner.countdown
	get_tree().paused = true
	for i in range(20):
		await get_tree().physics_frame
	check(is_equal_approx(before, spawner.countdown), "Pause freezes wave countdown")
	get_tree().paused = false
	for i in range(1000):
		await get_tree().physics_frame
		check(spawner.monsters.size() <= 2, "Alive cap respected")
		check(hud.wave_label.text.contains("WAVE %d" % spawner.wave_number), "HUD shows current wave")
		if spawner.wave_number >= 4:
			break
		for monster in spawner.monsters.duplicate():
			if is_instance_valid(monster) and not monster.dead:
				monster.take_damage(100000.0)
	check(counts == {1: 4, 2: 7, 3: 10}, "Wave totals increase without skipping pending monsters: " + str(counts))
	check(stats.size() == 3, "Three difficulty levels spawned")
	if stats.size() == 3:
		for wave in [2, 3]:
			for stat in range(3):
				check(stats[wave][stat] > stats[wave - 1][stat], "Health, damage and speed increase")
			check(stats[wave][3] < stats[wave - 1][3], "Attack interval decreases")
	spawner.reset_encounter()
	check(spawner.wave_number == 1 and spawner.wave_spawned == 0 and not spawner.between_waves, "Reset restores wave one")
	check(hud.wave_label.text.contains("WAVE 1"), "HUD refreshes after reset")
	print("WAVE PROGRESSION ", "FAILED" if failed else "PASSED")
	get_tree().quit(1 if failed else 0)