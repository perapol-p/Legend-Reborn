extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	data.progress_path = "user://test_fifteen_minute_progress.cfg"
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	var spawner = game.get_node("MonsterSpawner")
	spawner.enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.2).timeout
	game.get_node("Interface/PauseOverlay").hide()
	paused = false
	spawner.set_physics_process(false)
	spawner.enabled = true
	spawner.monster_spawned.connect(func(monster, _distance): monster.set_physics_process(false))
	var run = game.get_node("RunState")
	run.set_physics_process(false)
	for sample in [[0.0,40.0],[300.0,85.0],[600.0,160.0],[900.0,265.0]]:
		spawner.survival_time = sample[0]
		assert(is_equal_approx(spawner.monster_health(),sample[1]))
	spawner.survival_time = 899.0
	spawner.countdown = 1000.0
	spawner._physics_process(0.0)
	assert(not spawner.boss_phase)
	paused = true
	spawner._physics_process(5.0)
	assert(spawner.survival_time == 899.0)
	paused = false
	spawner._physics_process(1.0)
	assert(spawner.boss_phase and spawner.boss_started and spawner.boss.max_health == 10000.0)
	var boss_id: int = spawner.boss.get_instance_id()
	var hp: float = spawner.boss.health
	spawner.boss.take_damage(500.0)
	spawner.countdown = 0.0
	spawner._physics_process(60.0)
	assert(spawner.survival_time == 960.0)
	assert(spawner.boss.get_instance_id() == boss_id)
	assert(spawner.boss.health == hp - 500.0)
	assert(spawner.total_spawned > 1)
	assert(spawner.spawn_one() != null)
	assert(is_equal_approx(spawner.pressure_multiplier(),1.25))
	assert(spawner.current_spawn_interval() < 2.0 and spawner.spawn_batch_size() == 14)
	assert(spawner.monster_health() > 450.0)
	spawner.boss.advance_age(0.0)
	assert(spawner.boss.attack_damage == 25.0 and spawner.boss.move_speed > spawner.boss.base_move_speed)
	var previous: float = spawner.monster_health()
	spawner.countdown = 1000.0
	spawner._physics_process(120.0)
	assert(spawner.pressure_multiplier() > 1.25 and spawner.monster_health() > previous)
	assert(spawner.boss.health == hp - 500.0)
	print("PASS boss at15min once, ongoing spawns, increasing HP/speed/damage/fire rate, pause and no boss healing")
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	combat.equip("bow")
	var targets: Array[Node3D] = []
	for x in [20.0,23.0]:
		var target = load("res://scenes/training_dummy.tscn").instantiate()
		target.max_health = 10000.0
		target.position = Vector3(x,0,0)
		game.add_child(target)
		targets.append(target)
	var volley: Dictionary = {}
	for i in 3:
		var shot = combat.fire_projectile("bow",Vector3.FORWARD,100.0,38.0,0.04,true,0.0,Vector3(100,20,100),false,volley)
		shot.set_physics_process(false)
		shot.impact(targets[0],targets[0].global_position)
		shot.impact(targets[1],targets[1].global_position)
		shot.queue_free()
	assert(targets[0].health == 9830.0 and targets[1].health == 9830.0)
	var shot = combat.fire_projectile("bow",Vector3.FORWARD,100.0,38.0,0.04,true,0.0,Vector3(100,20,100),false,{})
	shot.set_physics_process(false)
	shot.impact(targets[0],targets[0].global_position)
	assert(targets[0].health == 9730.0)
	shot.queue_free()
	run.weapon_levels["bow"] = 2
	run.catalog.data["base_stats"]["crit_chance"] = 0.0
	combat.resolve_attack()
	var arrows: Array = []
	for node in get_nodes_in_group("weapon_projectiles"):
		if not node.is_queued_for_deletion():
			arrows.append(node)
	assert(arrows.size() == 3)
	for arrow in arrows:
		arrow.set_physics_process(false)
		arrow.impact(targets[1],targets[1].global_position)
	assert(is_equal_approx(targets[1].health,9796.0))
	print("PASS bow full/35%/35% per victim, piercing different victims full, new volley resets, real attack shares metadata")
	run.elapsed_time = 119.99
	assert(run.rarity_weights(40)["epic"] == 0)
	run.elapsed_time = 120.0
	assert(run.rarity_weights(7)["epic"] == 0 and run.rarity_weights(8)["epic"] > 0)
	run.elapsed_time = 300.0
	assert(run.rarity_weights(14)["legendary"] == 0 and run.rarity_weights(15)["legendary"] > 0)
	print("PASS item unlocks require both time and level")
	var target_boss = spawner.boss
	combat.deal_hit(target_boss,20000.0,"bow")
	await process_frame
	await process_frame
	assert(game.round_won and game.result_overlay.visible and paused)
	assert(not spawner.enabled)
	print("PASS boss kill still ends in victory")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(data.progress_path))
	quit()
