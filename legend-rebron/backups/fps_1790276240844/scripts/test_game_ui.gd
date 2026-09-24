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
	var run = game.get_node("RunState")
	var reward = game.get_node("Interface/RewardOverlay")
	run.rng.seed = 20260925
	assert(run.owned_ids.is_empty())
	hud.level_button.pressed.emit()
	assert(run.level == 2 and run.offers.size() == 3)
	assert(reward.visible and get_tree().paused)
	assert(hud.level_label.text == "LEVEL 2")
	assert(reward.choice_buttons.size() == 3)
	var frozen_time: float = hud.elapsed
	var frozen_combo: float = combo.remaining
	await get_tree().create_timer(0.1, true).timeout
	assert(hud.elapsed == frozen_time and combo.remaining == frozen_combo)
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await get_tree().process_frame
	assert(reward.visible and get_tree().paused and not overlay.visible)
	escape.pressed = false
	Input.parse_input_event(escape)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/reward_preview.png")
	var chosen: String = run.offers[0]
	reward.choice_buttons[0].pressed.emit()
	assert(run.owned_ids.has(chosen) and run.owned_ids.size() == 1)
	assert(not reward.visible and not get_tree().paused)
	assert(overlay.item_flow.get_child_count() == 1)
	assert(not run.choose_item(chosen))
	run.add_xp(run.xp_to_next() + run.xp_to_next() + 5)
	assert(run.level == 4 and reward.visible)
	assert(run.reward_level == 3)
	reward.choice_buttons[0].pressed.emit()
	assert(reward.visible and get_tree().paused and run.reward_level == 4)
	reward.choice_buttons[0].pressed.emit()
	assert(not reward.visible and not get_tree().paused)
	assert(run.owned_ids.size() == 3)
	hud.level_button.pressed.emit()
	var number := InputEventKey.new()
	number.physical_keycode = KEY_1
	number.pressed = true
	Input.parse_input_event(number)
	await get_tree().process_frame
	number.pressed = false
	Input.parse_input_event(number)
	assert(run.owned_ids.size() == 4 and not reward.visible and not get_tree().paused)
	overlay.toggle_pause()
	overlay.show_inventory()
	await get_tree().process_frame
	assert(overlay.item_flow.get_child_count() == 4)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/inventory_preview.png")
	overlay.show_stats(false)
	overlay.show_stats(true)
	overlay.toggle_pause()
	while run.remaining_count() > 0:
		hud.level_button.pressed.emit()
		assert(reward.choice_buttons.size() == mini(3, run.remaining_count()))
		reward.choice_buttons[0].pressed.emit()
	assert(run.owned_ids.size() == 20)
	assert(hud.hp_label.text == "HP    620 / 620")
	hud.level_button.pressed.emit()
	assert(not reward.visible and not get_tree().paused)
	assert(hud.xp_label.text.contains("All items collected"))
	overlay.toggle_pause()
	overlay.show_inventory()
	await get_tree().process_frame
	assert(overlay.item_flow.get_child_count() == 20)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/inventory_full_preview.png")
	overlay.toggle_pause()
	print("PASS: HUD/combo, pause, reward choices/button/keyboard, Esc lock, queued picks, live stats/inventory, exhausted pool")
	get_tree().quit()
