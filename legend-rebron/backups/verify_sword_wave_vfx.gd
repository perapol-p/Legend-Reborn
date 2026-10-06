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
	combat.equip("sword")
	for level in [2, 3]:
		run.weapon_levels["sword"] = level
		var target = load("res://scenes/training_dummy.tscn").instantiate()
		target.max_health = 10000.0
		game.add_child(target)
		target.global_position = combat.player.global_position + Vector3(0, 0, -7)
		combat.resolve_attack()
		var shots = get_nodes_in_group("weapon_projectiles")
		assert(shots.size() == 1)
		var vfx = shots[0].get_node("SwordWaveVFX")
		assert(vfx.materials.size() == 3 and vfx.get_node("EnergySparks").emitting)
		await create_timer(0.12).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/sword_wave_lv" + str(level) + ".png")
		await create_timer(0.45).timeout
		assert(target.health < 10000.0)
		print("PASS wave LV", level, " crescent shader, trails, sparks and target damage")
		target.free()
		for shot in get_nodes_in_group("weapon_projectiles"):
			shot.queue_free()
		await process_frame
	quit()
