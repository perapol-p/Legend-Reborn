extends SceneTree
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	root.get_node("GameSession").persistence_enabled = false
	var model = load("res://player/stats/progression.gd").new()
	model.persistence_enabled = false
	root.add_child(model)
	check(model.points == 3 and model.value("Hp") == 100, "starter build")
	check(not model.upgrade("invalid"), "unknown stat rejected")
	check(model.upgrade("Hp") and model.points == 2 and model.value("Hp") == 120, "HP upgrade and point spending")
	model.points = 0
	check(not model.upgrade("Atk") and model.value("Atk") == 10, "insufficient points rejected")
	model.add_experience(375)
	check(model.level == 3 and model.experience == 125 and model.points == 6, "multiple level-ups preserve overflow and award points")
	model.ranks.Atk = 5
	check(model.upgrade_cost("Atk") == 2, "cost increases every five ranks")
	model.ranks.Atk = 50
	check(not model.upgrade("Atk"), "maximum rank enforced")
	model.queue_free()
	var progression = root.get_node("CharacterProgression")
	progression.persistence_enabled = false
	# Tests never write or erase the player's save.
	progression.level = 1
	progression.experience = 0
	progression.points = 20
	for stat in progression.KEYS:
		progression.ranks[stat] = 0
	var scene = load("res://demo_level/world_castle.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var player = get_first_node_in_group("player")
	check(player != null and player.stats != null, "stats attached to real player scene")
	var stats = player.stats
	check(player.health_system.total_health == 100 and player.health_system.current_health == 100, "player health initialized at 100")
	progression.upgrade("Hp")
	check(player.health_system.total_health == 120 and player.health_system.current_health == 120, "HP upgrade applied to health system")
	progression.upgrade("Atk")
	check(is_equal_approx(stats.attack_multiplier(), 1.2), "ATK multiplier applied")
	progression.upgrade("Spd")
	check(is_equal_approx(player.default_speed, 4.12), "SPD movement updated")
	progression.upgrade("Def")
	check(stats.incoming_damage(1) < 20, "DEF reduces damage")
	progression.upgrade("Stamina")
	check(progression.value("Stamina") == 115, "stamina capacity upgraded")
	stats.stamina = 10
	check(not stats.spend_stamina(25) and stats.stamina == 10, "exhausted action cannot spend energy")
	check(stats.spend_stamina(10) and stats.stamina == 0, "exact energy cost allowed")
	stats.recovery_delay = 0
	stats._physics_process(0.5)
	check(stats.stamina > 0, "stamina regenerates")
	player.health_system._on_damage_signal({"power": 1.0})
	check(player.health_system.current_health > 100 and player.health_system.current_health < 120, "damage is scaled and mitigated")
	player.health_system._on_health_signal({"power": 1.0})
	check(player.health_system.current_health == 120, "healing uses matching player scale")
	var menu = player.get_node("CharacterStatsMenu")
	menu.toggle_menu()
	check(paused and menu.opened and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "menu pauses game and releases mouse")
	await process_frame
	menu.toggle_menu()
	check(not paused and not menu.opened, "menu restores game state")
	var enemy = get_first_node_in_group("targets")
	check(enemy != null, "existing enemies loaded")
	if enemy:
		enemy.ragdoll_death = false
		enemy.last_hit_by_player = true
		var before: int = progression.experience
		enemy.death()
		enemy.death()
		check(progression.experience == before + enemy.experience_reward, "enemy death awards EXP exactly once")
	print("RESULT: %d failures" % failures)
	quit(1 if failures else 0)
