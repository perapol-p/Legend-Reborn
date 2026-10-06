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
	var music = game.music
	assert(music.playing and music.stream is AudioStreamMP3 and music.stream.loop)
	assert(music.bus == "Music" and music.stream.get_length() > 1.0)
	music.seek(music.stream.get_length()-0.05)
	await create_timer(0.5).timeout
	assert(music.playing and music.get_playback_position() < 1.0)
	paused = true
	var before: float = music.get_playback_position()
	await create_timer(0.15,true).timeout
	assert(music.playing and music.get_playback_position() >= before)
	paused = false
	var data = root.get_node("GameData")
	var original: float = data.music_volume
	data.music_volume = 0.0
	data.apply_settings()
	var bus := AudioServer.get_bus_index("Music")
	assert(bus >= 0 and AudioServer.is_bus_mute(bus))
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")))
	data.music_volume = original
	data.apply_settings()
	game.get_node("Player").receive_damage(10000.0)
	await process_frame
	await process_frame
	assert(game.result_overlay.visible and not music.playing)
	print("PASS music auto-start, true MP3 end-to-start loop, continues in pause, separate Music volume/mute, stops at Game Over")
	game.free()
	await process_frame
	quit()
