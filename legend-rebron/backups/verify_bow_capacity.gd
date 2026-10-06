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
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	var run = game.get_node("RunState")
	combat.equip("bow")
	for level in range(1, 6):
		run.weapon_levels["bow"] = level
		await physics_frame
		await physics_frame
		var capacity: int = [4, 6, 8, 10, 12][level - 1]
		assert(combat.bow_capacity() == capacity)
		assert(combat.bow_ammo == capacity)
		combat.update_status()
		assert(combat.ammo_label.text.ends_with("/ %d" % capacity))
		for i in capacity:
			var before: int = combat.projectiles_fired
			combat.resolve_attack()
			assert(combat.projectiles_fired - before == [1, 3, 6, 12, 12][level - 1])
			if level < 5:
				assert(combat.bow_ammo == capacity - i - 1)
				assert((combat.bow_reload > 0.0) == (i == capacity - 1))
			for arrow in get_nodes_in_group("weapon_projectiles"):
				arrow.queue_free()
		if level < 5:
			combat.cooldown = 0.0
			assert(not combat.try_attack())
			await create_timer(1.4).timeout
			assert(combat.bow_ammo == capacity)
			assert(combat.bow_reload == 0.0)
		else:
			await physics_frame
			await physics_frame
			assert(combat.bow_reload == 0.0 and combat.bow_ammo == capacity)
		print("PASS LV",level," capacity=",capacity," volley=",[1, 3, 6, 12, 12][level - 1]," reload and HUD")
	quit()
