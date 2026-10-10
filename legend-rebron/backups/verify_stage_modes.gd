extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var data = root.get_node("GameData")
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.get_node("Center/Menu/Play").pressed.emit()
	await process_frame
	await process_frame
	var select = current_scene
	assert(select.name == "StageSelect" and select.stage_buttons.size() == 3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/stage_selection.png")
	select.stage_buttons["practice"].pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.name == "CharacterSelect" and data.selected_stage == "practice")
	current_scene.free()
	for stage in ["grassland","desert","practice"]:
		data.selected_stage = stage
		var game = load("res://scenes/game_placeholder.tscn").instantiate()
		game.auto_pause_on_focus_loss = false
		root.add_child(game)
		current_scene = game
		await create_timer(0.25).timeout
		game.get_node("Interface/PauseOverlay").hide()
		paused = false
		var arena = game.get_node("Arena")
		var spawner = game.get_node("MonsterSpawner")
		assert(game.stage_id == stage)
		if stage == "practice":
			assert(arena.get_node("Floor/Mesh").mesh.material is ShaderMaterial)
			assert(spawner.sandbox_mode and not spawner.enabled and spawner.monsters.is_empty())
			assert(game.get_node("Interface/HUD").survival_label.text.contains("PRACTICE"))
			spawner._physics_process(1200.0)
			assert(not spawner.boss_phase)
			game.command_console.open_console()
			game.command_console.submit("/spawn archer 2")
			assert(spawner.monsters.size() == 2)
			for monster in spawner.monsters:
				assert(monster.is_in_group("archer_monsters"))
			game.command_console.submit("/spawn flyer")
			assert(spawner.monsters.size() == 3)
			game.command_console.submit("/spawn boss")
			assert(spawner.monsters.size() == 4 and not spawner.boss_phase)
			game.command_console.close_console()
		else:
			assert(not spawner.sandbox_mode and spawner.enabled)
			assert(arena.get_node("Floor/Mesh").mesh.material is StandardMaterial3D)
			assert(arena.has_node("Trees" if stage == "grassland" else "StoneRuins"))
			assert(spawner.survival_duration == 900.0)
			var count: int = spawner.monsters.size()
			game.command_console.submit("/spawn boss")
			assert(spawner.monsters.size() == count)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/stage_"+stage+".png")
		print("PASS ",stage," arena, mode, commands, boss rules, English selection")
		game._leave_result("res://scenes/main_menu.tscn")
		await process_frame
		await process_frame
		var lobby = current_scene
		lobby.free()
		await process_frame
		await process_frame
	data.selected_stage = "grassland"
	await process_frame
	await process_frame
	quit()


