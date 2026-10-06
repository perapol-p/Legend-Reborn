extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	data.selected_character = "Mommy"
	var wins_before: int = data.games_completed
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.2).timeout
	paused = false
	game.get_node("Interface/PauseOverlay").hide()
	var run = game.get_node("RunState")
	run.set_physics_process(false)
	run.regen_elapsed = 0.0
	run.damage_player(10.0)
	run._physics_process(0.99)
	assert(run.current_health() == 90.0)
	run._physics_process(0.01)
	assert(run.current_health() == 91.0)
	run._physics_process(3.0)
	assert(run.current_health() == 94.0)
	paused = true
	var elapsed_before: float = run.elapsed_time
	run._physics_process(10.0)
	assert(run.current_health() == 94.0 and run.elapsed_time == elapsed_before)
	paused = false
	run.damage_taken = 0.4
	run._physics_process(1.0)
	assert(run.current_health() == 100.0)
	for id in ["pencil", "pencil", "pencil", "pan", "g_string", "g_string", "red_dot", "boot", "clover_four"]:
		run.offers.assign([id])
		assert(run.choose_item(id))
	run.level = 13
	run.weapon_levels["bow"] = 3
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	for i in 2:
		var monster = load("res://scenes/monster.tscn").instantiate()
		game.add_child(monster)
		combat.deal_hit(monster, 25.0, "bow")
		assert(run.monsters_killed == i)
		combat.deal_hit(monster, 10.0, "bow")
		assert(run.monsters_killed == i + 1)
		combat.deal_hit(monster, 10.0, "bow")
		assert(run.monsters_killed == i + 1)
	var dummy = load("res://scenes/training_dummy.tscn").instantiate()
	game.add_child(dummy)
	combat.deal_hit(dummy, 1000.0, "bow")
	assert(run.monsters_killed == 2)
	run.elapsed_time = 185.75
	game.get_node("Interface/HUD")._process(0.0)
	var player = game.get_node("Player")
	player.receive_damage(10000.0)
	assert(run.finished and game.round_finished and paused)
	assert(run.current_health() == 0.0)
	assert(not player.input_enabled)
	await process_frame
	await process_frame
	var overlay = game.result_overlay
	assert(overlay.visible and not overlay.won)
	assert(overlay.summary["character"] == "Mommy")
	assert(overlay.summary["monsters_killed"] == 2)
	assert(overlay.summary["level"] == 13 and overlay.summary["weapon_level"] == 3)
	assert(overlay.summary["elapsed_seconds"] == 185.75)
	assert(overlay.summary["item_total"] == 9)
	assert(overlay.summary["stats"]["attack"] == 70)
	assert(overlay.summary["health"] == 0.0)
	assert(data.games_completed == wins_before)
	run._physics_process(10.0)
	assert(run.current_health() == 0.0 and run.elapsed_time == 185.75)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/game_over_summary.png")
	overlay.retry_button.pressed.emit()
	await process_frame
	await process_frame
	var replay = current_scene
	assert(not replay.round_finished and not replay.get_node("RunState").finished)
	assert(replay.get_node("RunState").level == 1 and replay.get_node("RunState").monsters_killed == 0)
	assert(replay.get_node("RunState").owned_ids.is_empty())
	assert(replay.get_node("RunState").current_health() == 100.0)
	replay.get_node("Player").receive_damage(10000.0)
	await process_frame
	await process_frame
	replay.result_overlay.main_menu_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.name == "MainMenu" and not paused)
	print("PASS regen 1HP/s, full-health cap, pause and death stop; real monster kills; full Game Over summary; retry clears run; main menu; losses do not count as wins")
	quit()
