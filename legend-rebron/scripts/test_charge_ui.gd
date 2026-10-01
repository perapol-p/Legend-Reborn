extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("check_ui")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
func mouse(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/" + name + ".png")
func check_ui() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await process_frame
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	var hud = game.get_node("Interface/HUD")
	var run = game.get_node("RunState")
	combat.equip("gun")
	combat.gun_ammo = 6
	combat.update_status()
	await frames(2)
	check(combat.ammo_label.text == "06 / 12" and combat.ammo_label.get_theme_font_size("font_size") == 44, "Large ammo label")
	var rect: Rect2 = combat.ammo_label.get_global_rect()
	check(rect.position.x > root.size.x * 0.6 and rect.position.y > root.size.y * 0.6, "Ammo at bottom right")
	check(combat.ability_status.text.is_empty() and not combat.charge_meter.visible, "No top ammo text or meter below LV3")
	await capture("ammo_bottom_right")
	run.weapon_levels["gun"] = 3
	combat.unlock_charge()
	run.changed.emit()
	await mouse(true)
	await frames(70)
	check(combat.charge_time > 1.0 and combat.charge_meter.visible, "Holding mouse fills charge meter")
	check(hud.weapon_ability_label.text.is_empty() and combat.ability_status.text.is_empty(), "Charge text removed")
	await capture("charge_dual_meter")
	await mouse(false)
	await frames(2)
	check(combat.empowered > 0.0 and combat.charge_time == 0.0 and combat.ammo_label.text.contains("∞"), "Release triggers burst and shows unlimited ammo")
	await capture("charge_power_burst")
	game.command_console.open_console()
	await process_frame
	await process_frame
	check(not combat.charge_meter.visible, "Meter hides in console")
	game.command_console.close_console()
	combat.equip("sword")
	await frames(2)
	check(not combat.ammo_label.visible and not combat.charge_meter.visible, "Gun UI hides with other weapon")
	if not failed:
		print("PASS: bottom-right large ammo, dual curved charge meters, hold/release burst, removed charge text, console and weapon visibility")
	quit(1 if failed else 0)