extends Node
func _ready() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game)
	await get_tree().process_frame
	var combo = game.get_node("Combo")
	var hud = game.get_node("Interface/HUD")
	var overlay = game.get_node("Interface/PauseOverlay")
	assert(hud.clock_label.text == "00:00")
	assert(hud.clock_label.get_global_rect().position.x > 0)
	assert(hud.rank_label.get_global_rect().position.x > 0)
	assert(hud.rank_label.get_global_rect().end.x <= get_viewport().get_visible_rect().size.x)
	combo.register_hit()
	assert(hud.rank_label.text == "F")
	for i in range(9):
		combo.register_kill()
	assert(hud.rank_label.text == "SSS")
	assert(hud.flames.emitting)
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/hud_preview.png")
	overlay.toggle_pause()
	assert(get_tree().paused and overlay.visible)
	var saved_time: float = combo.remaining
	var saved_elapsed: float = hud.elapsed
	await get_tree().create_timer(0.1, true).timeout
	assert(combo.remaining == saved_time)
	assert(hud.elapsed == saved_elapsed)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/pause_preview.png")
	overlay.show_inventory()
	overlay.show_settings()
	overlay.show_controls()
	overlay.show_stats(true)
	overlay.toggle_pause()
	assert(not get_tree().paused and not overlay.visible)
	combo.advance(4.0)
	assert(hud.rank_label.text == "SS")
	assert(not hud.flames.emitting)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	hud._unhandled_key_input(key)
	assert(combo.points == 0)
	print("PASS: HUD sync, SSS flames, pause freezes timers, panels, resume, decay, reset key")
	get_tree().quit()
