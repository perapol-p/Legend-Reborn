extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	data.progress_path = "user://test_twenty_minute_progress.cfg"
	var prior_wins: int = data.games_completed
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
	for sample in [[0.0,1], [119.99,1], [120.0,2], [240.0,3], [1080.0,10]]:
		spawner.survival_time = sample[0]
		spawner.countdown = 1000.0
		spawner._physics_process(0.0)
		assert(spawner.spawn_batch_size() == sample[1])
	assert(spawner.max_alive == 100)
	assert(spawner.monster_health() == 2100.0)
	spawner.survival_time = 1199.0
	spawner._physics_process(0.0)
	assert(not spawner.boss_phase)
	paused = true
	spawner._physics_process(10.0)
	assert(spawner.survival_time == 1199.0 and not spawner.boss_phase)
	paused = false
	spawner._physics_process(1.0)
	assert(spawner.boss_phase and spawner.boss_started)
	assert(is_instance_valid(spawner.boss))
	assert(spawner.boss.max_health == 6000.0)
	assert(spawner.boss.is_in_group("bosses"))
	assert(spawner.spawn_one() == null)
	var total: int = spawner.total_spawned
	spawner._physics_process(20.0)
	assert(spawner.total_spawned == total)
	var hud = game.get_node("Interface/HUD")
	hud.refresh_survival()
	assert(hud.boss_bar.visible)
	combat_camera(game).look_at(spawner.boss.aim_point(), Vector3.UP)
	hud._process(0.0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/twenty_minute_boss.png")
	game.get_node("Player/Head/Camera3D/Combat").deal_hit(spawner.boss, 10000.0, "sword")
	await process_frame
	await process_frame
	assert(spawner.completed and game.round_won)
	assert(paused and game.victory_overlay.visible)
	assert(data.games_completed == prior_wins + 1)
	assert(not game.get_node("Player").input_enabled)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/twenty_minute_victory.png")
	game._show_victory()
	assert(data.games_completed == prior_wins + 1)
	print("PASS spawn growth every 120s, batch cap10, population cap100, pause, boss at1200s, no regular spawns, boss death, victory UI, saved completion")
	game._leave_result("res://scenes/game_placeholder.tscn")
	await process_frame
	await process_frame
	var replay = current_scene
	assert(replay != game and not replay.round_won)
	assert(not replay.get_node("MonsterSpawner").boss_phase)
	assert(replay.get_node("MonsterSpawner").survival_time < 1.0)
	replay._leave_result("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	assert(current_scene.name == "MainMenu" and not paused)
	print("PASS replay resets run, lobby navigation unpauses")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(data.progress_path))
	quit()



func combat_camera(game: Node) -> Camera3D:
	return game.get_node("Player/Head/Camera3D")
