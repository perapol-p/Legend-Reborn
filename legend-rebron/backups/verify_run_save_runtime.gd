extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	data.active_run_path = "user://test_run_runtime.save"
	data.selected_stage = "desert"
	data.selected_character = "Mommy"
	data.pending_resume = {}
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	current_scene = game
	var run = game.get_node("RunState")
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	var spawner = game.get_node("MonsterSpawner")
	run.level = 12
	run.weapon_levels["bow"] = 3
	run.damage_taken = 13.0
	run.elapsed_time = 751.3
	run.regen_elapsed = 0.45
	combat.known_bow_capacity = 8
	combat.bow_ammo = 2
	combat.bow_reload = 0.7
	spawner.survival_time = 751.3
	spawner.started = true
	var actors: Array = []
	for type in ["archer","flyer"]:
		var actor = spawner.spawn_one(false,type)
		assert(actor != null)
		actor.max_health = 500.0
		actor.health = 500.0
		actors.append(actor)
	actors[0].windup_remaining = 0.33
	actors[0].locked_target = Vector3(0,1,12)
	var volley: Dictionary = {}
	for i in 3:
		var shot = combat.fire_projectile("bow",Vector3.FORWARD,100.0,38.0,0.04,true,0.0,Vector3(50,20,50),true,volley)
		if i == 0:
			shot.impact(actors[0],actors[0].global_position)
	var enemy = load("res://scripts/enemy_projectile.gd").new()
	enemy.player = game.get_node("Player")
	enemy.kind = "fireball"
	enemy.velocity = Vector3(0,0,8)
	enemy.gravity = 0.0
	enemy.remaining = 0.8
	enemy.distance_travelled = 2.0
	enemy.excluded.assign([actors[0].get_rid()])
	enemy.position = Vector3(20,15,20)
	game.add_child(enemy)
	var tornado = combat.spawn_tornado(Vector3(40,3,0),10.0,2.0,1.7,true)
	tornado.pulse = 0.2
	tornado.model.rotation.y = 1.25
	var target = load("res://scripts/gun_charge_target.gd").new()
	target.source = combat
	target.remaining = 1.1
	target.position = Vector3(0,4,0)
	game.add_child(target)
	run.offers.assign(["pencil","pan","red_dot"])
	run.reward_level = 12
	run.offer_generation = 37
	run.pending_levels.assign([13])
	game._sync_reward()
	var random_state: int = run.rng.state
	assert(game.save_checkpoint() == OK)
	var saved: Dictionary = data.load_active_run()
	assert(saved["shots"].size() == 3 and saved["volleys"].size() == 1)
	game.free()
	data.pending_resume = saved
	var resumed = load("res://scenes/game_placeholder.tscn").instantiate()
	resumed.auto_pause_on_focus_loss = false
	root.add_child(resumed)
	current_scene = resumed
	var restored = resumed.get_node("RunState")
	assert(paused and resumed.get_node("Interface/RewardOverlay").visible)
	assert(restored.offers == ["pencil","pan","red_dot"] and restored.offer_generation == 37)
	assert(restored.pending_levels == [13] and restored.rng.state == random_state)
	assert(restored.damage_taken == 13.0 and restored.elapsed_time == 751.3)
	var new_combat = resumed.get_node("Player/Head/Camera3D/Combat")
	assert(new_combat.bow_ammo == 2 and new_combat.bow_reload == 0.7)
	var new_actors = resumed.get_node("MonsterSpawner").monsters
	assert(new_actors.size() == 2 and new_actors[0].windup_remaining == 0.33)
	var shots = get_nodes_in_group("weapon_projectiles")
	assert(shots.size() == 3 and shots[0].critical)
	assert(shots[0].struck.has(new_actors[0].get_rid()))
	assert(is_same(shots[0].bow_volley_hits,shots[1].bow_volley_hits))
	shots[1].impact(new_actors[0],new_actors[0].global_position)
	assert(new_actors[0].health == 365.0)
	assert(get_nodes_in_group("enemy_projectiles").size() == 1)
	var new_enemy = get_nodes_in_group("enemy_projectiles")[0]
	assert(new_enemy.excluded.has(new_actors[0].get_rid()) and new_enemy.remaining == 0.8)
	assert(get_nodes_in_group("weapon_tornadoes").size() == 1)
	assert(get_nodes_in_group("weapon_tornadoes")[0].model.rotation.y == 1.25)
	assert(get_nodes_in_group("gun_charge_targets").size() == 1)
	print("PASS queued item choices/RNG, ranged windup, ammo/reload, projectile critical/struck/volley identity, enemy shots, tornado and charge targets survive save/load")
	resumed.free()
	data.clear_active_run()
	data.pending_resume = {}
	var fresh = load("res://scenes/game_placeholder.tscn").instantiate()
	fresh.auto_pause_on_focus_loss = false
	root.add_child(fresh)
	current_scene = fresh
	fresh.get_node("Player").receive_damage(10000.0)
	await process_frame
	await process_frame
	assert(data.load_active_run().is_empty())
	fresh.free()
	print("PASS Game Over invalidates Continue slot")
	quit()
