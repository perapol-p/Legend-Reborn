extends SceneTree
const Codec = preload("res://scripts/run_save_codec.gd")
func _initialize() -> void:
	call_deferred("verify")
func new_game(stage: String) -> Node:
	var data = root.get_node("GameData")
	data.selected_stage = stage
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	current_scene = game
	return game
func verify() -> void:
	var data = root.get_node("GameData")
	data.active_run_path = "user://test_single_active_run.save"
	data.progress_path = "user://test_single_active_progress.cfg"
	data.clear_active_run()
	data.selected_character = "Daddy"
	var game = new_game("grassland")
	var run = game.get_node("RunState")
	var player = game.get_node("Player")
	var combat = player.get_node("Head/Camera3D/Combat")
	var spawner = game.get_node("MonsterSpawner")
	assert(data.load_active_run()["stage"] == "grassland")
	run.level = 10
	run.xp = 11
	run.elapsed_time = 210.5
	run.monsters_killed = 55
	run.offers.assign(["pencil"])
	run.choose_item("pencil")
	run.weapon_levels["sword"] = 2
	run.damage_taken = 17.0
	player.global_position = Vector3(3,0.08,12)
	combat.gun_ammo = 7
	combat.bow_ammo = 2
	spawner.survival_time = 210.5
	spawner.countdown = 1.4
	spawner.started = true
	var actor = spawner.spawn_one(false,"melee")
	assert(actor != null)
	actor.health = 31.0
	actor.alive_seconds = 60.0
	actor.attack_timer = 0.7
	var saved_actor_position: Vector3 = actor.global_position
	game.get_node("Combo").add_points(77)
	paused = true
	assert(game.save_checkpoint() == OK)
	var loaded: Dictionary = data.load_active_run()
	assert(loaded["run"]["level"] == 10 and loaded["actors"].size() == 1)
	game.get_node("Interface/PauseOverlay").return_to_menu()
	await process_frame
	await process_frame
	var menu = current_scene
	assert(menu.name == "MainMenu")
	assert(menu.get_node("Center/Menu/Continue").visible)
	assert(menu.get_node("Center/Menu/Continue").text.contains("LV 10"))
	menu.get_node("Center/Menu/Continue").pressed.emit()
	await process_frame
	var continued = current_scene
	var restored = continued.get_node("RunState")
	assert(restored.level == 10 and restored.xp == 11 and restored.monsters_killed == 55)
	assert(restored.stack_count("pencil") == 1 and restored.weapon_level("sword") == 2)
	assert(is_equal_approx(restored.damage_taken,17.0))
	assert(continued.get_node("MonsterSpawner").monsters.size() == 1)
	var restored_actor = continued.get_node("MonsterSpawner").monsters[0]
	assert(restored_actor.health == 31.0 and restored_actor.global_position.distance_to(saved_actor_position) < 0.2)
	assert(continued.get_node("Player/Head/Camera3D/Combat").gun_ammo == 7)
	assert(continued.get_node("Combo").points == 77)
	print("PASS real Save/Go Back/Continue: stage, LV10, XP, items, weapon levels, health, ammo, combo and actor state")
	continued.free()
	paused = false
	data.pending_resume = {}
	var desert = new_game("desert")
	assert(data.load_active_run()["stage"] == "desert" and data.load_active_run()["run"]["level"] == 1)
	desert.free()
	var practice = new_game("practice")
	assert(data.load_active_run()["stage"] == "desert")
	practice.free()
	print("PASS newest Normal replaces one slot; Practice does not overwrite")
	var boss_game = new_game("desert")
	var boss_spawner = boss_game.get_node("MonsterSpawner")
	boss_spawner.survival_time = 945.0
	boss_spawner.boss_phase = true
	boss_spawner._try_spawn_boss()
	assert(is_instance_valid(boss_spawner.boss))
	boss_spawner.boss.health = 4321.0
	boss_game.get_node("RunState").elapsed_time = 945.0
	assert(boss_game.save_checkpoint() == OK)
	loaded = data.load_active_run()
	boss_game.free()
	data.pending_resume = loaded
	var resumed_boss = new_game("desert")
	var resumed_spawner = resumed_boss.get_node("MonsterSpawner")
	assert(resumed_spawner.boss_phase and resumed_spawner.boss_started)
	assert(resumed_spawner.boss.health == 4321.0 and resumed_spawner.survival_time == 945.0)
	assert(resumed_boss.get_node("RunState").elapsed_time == 945.0)
	resumed_boss.get_node("Player/Head/Camera3D/Combat").deal_hit(resumed_spawner.boss,20000.0,"sword")
	await process_frame
	await process_frame
	assert(resumed_boss.round_won and data.load_active_run().is_empty())
	resumed_boss.free()
	print("PASS boss HP/time preserved; victory clears the active save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(data.active_run_path))
	quit()


