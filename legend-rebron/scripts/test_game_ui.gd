extends Node
var game: Node
func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
func send_key(keycode: int, pressed: bool) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	key.keycode = keycode
	key.pressed = pressed
	Input.parse_input_event(key)
	await get_tree().process_frame
func capture(path: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/" + path)
func _ready() -> void:
	GameData.settings_path = "user://fps_test_settings.cfg"
	GameData.restore_defaults()
	game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.auto_pause_on_focus_loss = false
	add_child(game)
	await frames(12)
	var player = game.get_node("Player")
	var combo = game.get_node("Combo")
	var hud = game.get_node("Interface/HUD")
	var pause = game.get_node("Interface/PauseOverlay")
	var reward = game.get_node("Interface/RewardOverlay")
	var run = game.get_node("RunState")
	var crosshair = game.get_node("Interface/Crosshair")
	assert(player.is_on_floor())
	assert(crosshair.visible and GameData.crosshair_style == "plus" and GameData.crosshair_color == "white")
	await capture("fps_preview.png")
	var start: Vector3 = player.position
	Input.action_press("move_forward")
	await frames(20)
	assert(player.position.z < start.z - 1.0)
	var walking_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	Input.action_press("sprint")
	await frames(12)
	assert(Vector2(player.velocity.x, player.velocity.z).length() > walking_speed + 1.0)
	Input.action_release("sprint")
	Input.action_release("move_forward")
	await frames(12)
	Input.action_press("jump")
	await frames(3)
	Input.action_release("jump")
	assert(player.position.y > 0.1 and player.velocity.y > 0)
	var air_x: float = player.position.x
	Input.action_press("move_right")
	await frames(8)
	Input.action_release("move_right")
	assert(player.position.x > air_x)
	await frames(65)
	player.respawn()
	await frames(12)
	var dash_start: Vector3 = player.position
	Input.action_press("dash")
	await frames(6)
	Input.action_release("dash")
	assert(player.position.z < dash_start.z - 1.0)
	assert(player.dash_recovery > 0)
	player.respawn()
	player.position.z = -30
	await frames(12)
	Input.action_press("move_forward")
	await frames(30)
	Input.action_release("move_forward")
	assert(player.position.z > -31.3)
	player.respawn()
	player.position = Vector3(-18, 0.1, 1)
	await frames(12)
	Input.action_press("move_forward")
	await frames(112)
	Input.action_release("move_forward")
	assert(player.position.y > 2.7 and player.is_on_floor(), "Ramp climb ended at " + str(player.position))
	player.position.y = -25
	await frames(2)
	assert(player.position.y > -1)
	player.respawn()
	await frames(10)
	var yaw: float = player.rotation.y
	player.apply_look(Vector2(25, 10))
	assert(player.rotation.y < yaw and player.head.rotation.x < 0)
	GameData.invert_y = true
	player.head.rotation.x = 0
	player.apply_look(Vector2(0, 10))
	assert(player.head.rotation.x > 0)
	GameData.invert_y = false
	player.respawn()
	GameData.rebind("move_forward", KEY_UP)
	assert(not InputMap.event_is_action(_event(KEY_W), "move_forward"))
	assert(InputMap.event_is_action(_event(KEY_UP), "move_forward"))
	start = player.position
	await send_key(KEY_UP, true)
	await frames(15)
	await send_key(KEY_UP, false)
	assert(player.position.z < start.z - 0.5)
	GameData.rebind("move_forward", KEY_S)
	assert(GameData.bindings["move_forward"] == KEY_S)
	assert(GameData.bindings["move_back"] == KEY_UP)
	GameData.load_settings()
	assert(GameData.bindings["move_forward"] == KEY_S and GameData.bindings["move_back"] == KEY_UP)
	GameData.restore_defaults()
	player.respawn()
	await frames(10)
	combo.register_hit()
	assert(hud.rank_label.text == "F")
	for i in range(9):
		combo.register_kill()
	assert(hud.rank_label.text == "SSS" and hud.flames.emitting)
	pause.toggle_pause()
	assert(get_tree().paused and not player.input_enabled and not crosshair.visible)
	var frozen: Vector3 = player.position
	var frozen_combo: float = combo.remaining
	var frozen_time: float = hud.elapsed
	await get_tree().create_timer(0.1, true).timeout
	assert(player.position == frozen and combo.remaining == frozen_combo and hud.elapsed == frozen_time)
	pause.show_settings()
	var panel = pause.content.get_child(0)
	panel.show_page("Keyboard")
	await capture("keyboard_settings_preview.png")
	panel.begin_rebind("jump")
	await send_key(KEY_E, true)
	await send_key(KEY_E, false)
	assert(GameData.bindings["jump"] == KEY_E and not GameData.rebinding_active)
	panel.begin_rebind("move_forward")
	await send_key(KEY_ESCAPE, true)
	await send_key(KEY_ESCAPE, false)
	assert(get_tree().paused and not GameData.rebinding_active)
	assert(GameData.bindings["move_forward"] == KEY_W)
	panel.begin_rebind("jump")
	pause.toggle_pause()
	assert(not GameData.rebinding_active and player.input_enabled)
	pause.toggle_pause()
	pause.show_settings()
	panel = pause.content.get_child(0)
	panel.show_page("Crosshair")
	panel.style_picker.select(2)
	panel.style_picker.item_selected.emit(2)
	panel.color_picker.select(1)
	panel.color_picker.item_selected.emit(1)
	panel.size_slider.value = 30
	assert(GameData.crosshair_style == "gap" and GameData.crosshair_color == "red" and GameData.crosshair_size == 30)
	GameData.crosshair_style = "dot"
	GameData.crosshair_color = "black"
	GameData.crosshair_size = 8
	GameData.load_settings()
	assert(GameData.crosshair_style == "gap" and GameData.crosshair_color == "red" and GameData.crosshair_size == 30)
	await capture("crosshair_settings_preview.png")
	for shape in GameData.CROSSHAIR_STYLES:
		for color in GameData.CROSSHAIR_COLORS:
			GameData.crosshair_style = shape
			GameData.crosshair_color = color
			GameData.settings_changed.emit()
			await get_tree().process_frame
	GameData.restore_defaults()
	pause.toggle_pause()
	assert(crosshair.visible and player.input_enabled)
	run.rng.seed = 20260925
	hud.level_button.pressed.emit()
	assert(run.level == 2 and reward.choice_buttons.size() == 3 and get_tree().paused)
	assert(not player.input_enabled and not crosshair.visible)
	await send_key(KEY_ESCAPE, true)
	await send_key(KEY_ESCAPE, false)
	assert(reward.visible and get_tree().paused)
	await capture("stack_reward_preview.png")
	var chosen: String = run.offers[0]
	reward.choice_buttons[0].pressed.emit()
	assert(run.stack_count(chosen) == 1 and not get_tree().paused)
	for i in range(9):
		hud.level_button.pressed.emit()
		run.offers.assign([chosen])
		game._sync_reward()
		reward.choice_buttons[0].pressed.emit()
	assert(run.stack_count(chosen) == 10 and run.total_items() == 10 and run.owned_ids.size() == 1)
	assert(is_equal_approx(player.speed_multiplier(), float(run.stats()["speed"]) / 100.0))
	pause.toggle_pause()
	pause.show_inventory()
	await get_tree().process_frame
	assert(pause.item_flow.get_child_count() == 1)
	assert(pause.item_flow.get_child(0).get_child(0).text.ends_with("×10"))
	await capture("stack_inventory_preview.png")
	pause.toggle_pause()
	hud.level_button.pressed.emit()
	await send_key(KEY_1, true)
	await send_key(KEY_1, false)
	assert(run.total_items() == 11 and not get_tree().paused)
	await send_key(KEY_TAB, true)
	await send_key(KEY_TAB, false)
	assert(not player.input_enabled and not crosshair.visible)
	await send_key(KEY_TAB, true)
	await send_key(KEY_TAB, false)
	assert(player.input_enabled and crosshair.visible)
	for path in ["res://scenes/settings.tscn", "res://scenes/controls.tscn"]:
		var menu = load(path).instantiate()
		add_child(menu)
		await get_tree().process_frame
		menu.queue_free()
		await get_tree().process_frame
	print("PASS: FPS ground/jump/air/dash/collision/respawn/look; remap+save; 15 crosshairs+save; pause/cursor; stack rewards+inventory")
	get_tree().quit()
func _event(keycode: int) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	return key
