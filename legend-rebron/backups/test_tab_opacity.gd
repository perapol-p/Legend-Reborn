extends SceneTree
func _initialize() -> void:
	call_deferred("check_ui")
func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	for i in range(4):
		await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/" + name + ".png")
func check_ui() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await process_frame
	var overlay = game.get_node("Interface/PauseOverlay")
	var player = game.get_node("Player")
	var data = root.get_node("GameData")
	data.settings_path = "user://tab_hold_test.cfg"
	data.restore_defaults()
	await key(KEY_TAB, true)
	assert(paused and overlay.visible and overlay.overlay_mode == "stats" and not player.input_enabled)
	assert(overlay.heading.text == "Stats" and overlay.content.get_child_count() == 10)
	assert(is_equal_approx(overlay.stats_panel.get_theme_stylebox("panel").bg_color.a, 0.65))
	await capture("tab_combined_new")
	await key(KEY_TAB, false)
	assert(not paused and not overlay.visible and player.input_enabled)
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	assert(paused and overlay.menu.visible and not overlay.stats_panel.visible)
	var menu_center: Vector2 = overlay.menu.get_global_rect().get_center()
	assert(menu_center.distance_to(root.get_visible_rect().get_center()) < 2.0, str(menu_center))
	await capture("paused_centered_new")
	await key(KEY_TAB, true)
	await key(KEY_TAB, false)
	assert(paused and overlay.overlay_mode == "menu")
	overlay.show_settings()
	assert(overlay.stats_panel.visible)
	var settings = overlay.content.get_child(0)
	settings.opacity_slider.value = 25
	assert(is_equal_approx(data.tab_ui_opacity, 0.25))
	data.tab_ui_opacity = 1.0
	data.load_settings()
	assert(is_equal_approx(data.tab_ui_opacity, 0.25))
	data.apply_settings()
	overlay.toggle_pause()
	await key(KEY_TAB, true)
	assert(is_equal_approx(overlay.stats_panel.get_theme_stylebox("panel").bg_color.a, 0.25))
	assert(is_equal_approx(overlay.content.modulate.a, 1.0))
	await capture("tab_transparent_new")
	data.tab_ui_opacity = 0.0
	data.settings_changed.emit()
	assert(is_zero_approx(overlay.stats_panel.get_theme_stylebox("panel").bg_color.a) and is_zero_approx(overlay.shade.color.a))
	data.tab_ui_opacity = 1.0
	data.settings_changed.emit()
	assert(is_equal_approx(overlay.stats_panel.get_theme_stylebox("panel").bg_color.a, 1.0))
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	assert(paused and overlay.overlay_mode == "menu")
	await key(KEY_TAB, false)
	assert(paused and overlay.menu.visible)
	overlay.toggle_pause()
	await key(KEY_TAB, true)
	overlay._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await key(KEY_TAB, false)
	assert(paused and overlay.overlay_mode == "menu")
	overlay.toggle_pause()
	assert(not paused and player.input_enabled)
	print("PASS: combined stats, opacity slider, save/load, live 0/25/100% backgrounds, readable text, hold Tab, centered pause and settings")
	quit()