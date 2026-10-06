extends Node
var failed := false
var samples: Array[float] = []
var game: Node
var spawner: Node
var player: CharacterBody3D
func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + message)
func spawned(monster: CharacterBody3D, distance: float) -> void:
	var actual := Vector2(monster.global_position.x - player.global_position.x, monster.global_position.z - player.global_position.z).length()
	check(actual >= spawner.spawn_radius + 0.4 and actual <= spawner.outer_radius + 0.01, "Spawn outside ring and within band")
	check(absf(distance - actual) < 0.01, "Debug distance matches world distance")
	samples.append(actual)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.auto_pause_on_focus_loss = false
	player = game.get_node("Player")
	spawner = game.get_node("MonsterSpawner")
	spawner.monster_spawned.connect(spawned)
	add_child(game)
	await frames(25)
	check(spawner.monsters.size() == 4, "Initial four monsters")
	var first: CharacterBody3D = spawner.monsters[0]
	var initial_distance := first.global_position.distance_to(player.global_position)
	await frames(60)
	check(first.global_position.distance_to(player.global_position) < initial_distance - 1.0, "Monster chases")
	if OS.get_cmdline_user_args().has("--preview"):
		var toward: Vector3 = first.global_position - player.global_position
		player.rotation.y = atan2(-toward.x, -toward.z)
		player.head.rotation.x = -0.18
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/monster_spawn_first_person.png")
		var overview := Camera3D.new()
		game.add_child(overview)
		overview.position = player.position + Vector3(0, 42, 32)
		overview.look_at(player.position)
		overview.current = true
		await frames(2)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/monster_spawn_overview.png")
		overview.queue_free()
		player.camera.current = true
		player.head.rotation.x = 0
		player.rotation.y = 0
	# Pause freezes both spawn timer and monsters.
	var before_count: int = spawner.total_spawned
	var before_position: Vector3 = first.global_position
	get_tree().paused = true
	await frames(150)
	check(spawner.total_spawned == before_count and first.global_position.is_equal_approx(before_position), "Pause freezes spawning and AI")
	get_tree().paused = false
	spawner.show_debug_radius = false
	spawner.update_debug()
	check(not spawner.ring.visible and not spawner.info.visible and not spawner.markers.visible, "All debug helpers hide together")
	spawner.reset_encounter()
	await frames(2)
	# Sample many spawn points around moving player positions without AI drift.
	spawner.countdown = 1000
	var quadrants: Dictionary = {}
	for i in range(100):
		player.position = Vector3(float(i % 5) * 30.0, 0.1, float(i % 7) * 20.0)
		player.velocity = Vector3.ZERO
		var monster: CharacterBody3D = spawner.spawn_one()
		check(monster != null, "Valid ground supports spawn")
		if monster != null:
			var offset := monster.global_position - player.global_position
			quadrants[Vector2i(1 if offset.x >= 0 else -1, 1 if offset.z >= 0 else -1)] = true
			monster.queue_free()
		await frames(1)
	check(quadrants.size() == 4, "Spawns cover all sides")
	spawner.show_debug_radius = true
	spawner.update_debug()
	check(is_equal_approx(spawner.ring.global_position.x, player.global_position.x) and is_equal_approx(spawner.ring.global_position.z, player.global_position.z), "Ring follows player position")
	spawner.reset_encounter()
	await frames(2)
	spawner.countdown = 1000
	for i in range(24):
		spawner.spawn_one()
	check(spawner.monsters.size() >= 24, "Population exceeds the former 16-monster cap")
	check(spawner.spawn_one() != null, "Spawning continues beyond former cap")
	spawner.reset_encounter()
	await frames(2)
	player.position = Vector3(1000, 0.1, 1000)
	check(spawner.spawn_one() == null, "No spawn without ground")
	player.position = Vector3(499, 0.1, 0)
	var edge_monster: CharacterBody3D = spawner.spawn_one()
	check(edge_monster != null, "Spawn near arena edge finds safe ground")
	if edge_monster != null:
		check(absf(edge_monster.position.x) < 500 and absf(edge_monster.position.z) < 500, "Edge spawn stays on floor")
	spawner.reset_encounter()
	spawner.enabled = false
	await frames(2)
	player.respawn()
	await frames(5)
	# Each existing weapon damages and kills actual monsters; kills give XP.
	var run: Node = game.get_node("RunState")
	var combat: Node = player.get_node("Head/Camera3D/Combat")
	for id in combat.ORDER:
		run.xp = 0
		var monster: CharacterBody3D = load("res://scenes/monster.tscn").instantiate()
		monster.player = player
		monster.move_speed = 0
		monster.max_health = 8
		game.add_child(monster)
		monster.position = player.position + Vector3(0, 0, -2.6)
		await frames(3)
		combat.equip(id)
		combat.cooldown = 0
		combat.try_attack()
		await frames(60)
		check(not is_instance_valid(monster), "Weapon kills monster: " + id)
		check(run.xp == 3, "Monster grants XP: " + id)
	# Contact attack changes real health and HUD, death resets encounter.
	var attacker: CharacterBody3D = load("res://scenes/monster.tscn").instantiate()
	attacker.player = player
	attacker.move_speed = 0
	game.add_child(attacker)
	attacker.position = player.position + Vector3(0, 0, -1.3)
	var hp: float = run.current_health()
	await frames(50)
	check(run.current_health() < hp, "Monster attacks player")
	check(game.get_node("Interface/HUD").hp_bar.value < 100, "HUD shows damage")
	attacker.queue_free()
	await frames(2)
	spawner.enabled = true
	spawner.countdown = 1000
	spawner.spawn_one()
	player.receive_damage(10000)
	check(run.current_health() == run.stats()["max_hp"], "Death restores health for test respawn")
	check(spawner.monsters.is_empty(), "Death clears encounter")
	await frames(3)
	print("MONSTER INTEGRATION ", "FAILED" if failed else "PASSED", " | audited spawns: ", samples.size())
	get_tree().quit(1 if failed else 0)


