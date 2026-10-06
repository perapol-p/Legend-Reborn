extends SceneTree
var events: Array[float] = []
func _initialize() -> void:
	call_deferred("verify")
func target_at(game: Node, player: Node3D, distance: float) -> Node3D:
	var target = load("res://scenes/training_dummy.tscn").instantiate()
	target.max_health = 10000.0
	target.position = player.global_position + Vector3(0,0,-distance)
	game.add_child(target)
	return target
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.2).timeout
	game.get_node("Interface/PauseOverlay").hide()
	paused = false
	var run = game.get_node("RunState")
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	var player = game.get_node("Player")
	var hud = game.get_node("Interface/HUD")
	combat.critical_hit.connect(func(damage: float): events.append(damage))
	run.catalog.data["base_stats"]["crit_chance"] = 100.0
	for id in ["sword", "katana", "gun", "bow", "spellbook"]:
		player.respawn()
		combat.equip(id)
		var target = target_at(game,player,2.6 if id in ["sword","katana"] else 5.0)
		await physics_frame
		await physics_frame
		hud.critical_label.hide()
		hud.critical_remaining = 0.0
		var count_before: int = events.size()
		combat.resolve_attack()
		if id in ["bow","spellbook"]:
			assert(events.size() == count_before and not hud.critical_label.visible)
			var shots = get_nodes_in_group("weapon_projectiles")
			assert(not shots.is_empty() and shots[0].critical)
			# A later roll or weapon swap must not erase the shot's critical status.
			combat.equip("gun")
		await create_timer(0.35).timeout
		assert(events.size() > count_before)
		assert(target.health < 10000.0)
		assert(hud.critical_label.visible and hud.critical_label.text.contains("CRITICAL!"))
		print("PASS confirmed critical ",id," damage=",events.back())
		target.free()
		for shot in get_nodes_in_group("weapon_projectiles"):
			shot.queue_free()
		await process_frame
	player.respawn()
	combat.equip("gun")
	var target = target_at(game,player,5.0)
	await physics_frame
	await physics_frame
	run.catalog.data["base_stats"]["crit_chance"] = 0.0
	var count_before: int = events.size()
	combat.resolve_attack()
	assert(events.size() == count_before)
	assert(not combat.last_damage_critical)
	run.catalog.data["base_stats"]["crit_chance"] = 100.0
	combat.equip("spellbook")
	var damage: float = combat.roll_damage()
	var tornado = combat.spawn_tornado(target.global_position + Vector3.UP, damage * 0.45, 3.0, 1.0, combat.last_damage_critical)
	await create_timer(0.10).timeout
	assert(tornado.critical and events.size() > count_before)
	tornado.queue_free()
	count_before = events.size()
	combat.explode(target.global_position + Vector3.UP, 2.0, damage, null, true, "spellbook")
	assert(events.size() > count_before)
	target.free()
	await process_frame
	hud.critical_label.hide()
	hud.critical_remaining = 0.0
	count_before = events.size()
	combat.equip("gun")
	combat.resolve_attack()
	assert(events.size() == count_before and not hud.critical_label.visible)
	var combo = game.get_node("Combo")
	combo.add_points(1000)
	assert(combo.points > 1000 and hud.rank_label.text == "SSS")
	hud.show_critical(120.0)
	assert(hud.critical_label.global_position.y > hud.combo_info.global_position.y)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/critical_combo.png")
	hud._process(1.2)
	assert(not hud.critical_label.visible)
	print("PASS non-critical and misses do not notify, projectile metadata survives equip, tornado/splash crit, HUD below combo, fade, unlimited score")
	game.free()
	quit()
