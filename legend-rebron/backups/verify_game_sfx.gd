extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await frames(15)
	game.get_node("Interface/PauseOverlay").hide()
	paused = false
	var sfx = game.sfx
	for stream in sfx.SOUNDS.values():
		assert(stream.get_length() > 0.0)
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	combat.equip("sword")
	combat.cooldown = 0.0
	assert(combat.try_attack())
	assert(sfx.played["sword"] == 1)
	assert(not combat.try_attack())
	assert(sfx.played["sword"] == 1)
	combat.equip("bow")
	game.get_node("RunState").weapon_levels["bow"] = 4
	combat.resolve_attack()
	assert(sfx.played["bow"] == 1)
	var player = game.get_node("Player")
	Input.action_press("move_right")
	await frames(25)
	assert(sfx.played["footstep"] > 0)
	Input.action_press("dash")
	await frames(2)
	Input.action_release("dash")
	assert(sfx.played["dash"] == 1)
	Input.action_release("move_right")
	paused = true
	assert(not sfx.play_sound("sword"))
	sfx._physics_process(0.1)
	for voice in sfx.voices:
		assert(not voice.playing)
	paused = false
	var data = root.get_node("GameData")
	var original: float = data.effects_volume
	data.effects_volume = 0.0
	data.apply_settings()
	var bus := AudioServer.get_bus_index("Effects")
	assert(bus >= 0 and AudioServer.is_bus_mute(bus))
	data.effects_volume = original
	data.apply_settings()
	assert(not AudioServer.is_bus_mute(bus))
	print("PASS imported 4 SFX, sword accepted attack, bow once/volley, footsteps, dash, pause stops voices, Effects volume and mute")
	game.free()
	await process_frame
	await process_frame
	quit()

