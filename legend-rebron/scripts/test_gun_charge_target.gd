extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("check_skill")
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
func check_skill() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await process_frame
	var player = game.get_node("Player")
	var combat = player.get_node("Head/Camera3D/Combat")
	var run = game.get_node("RunState")
	combat.equip("gun")
	run.weapon_levels["gun"] = 3
	await frames(10)
	await mouse(true)
	await frames(10)
	await mouse(false)
	check(combat.charge_time == 0.0 and combat.empowered == 0.0 and combat.gun_ammo < 12, "LV3 shoots normally until target earned")
	combat.charge_target_chance = 0.0
	check(combat.try_spawn_charge_target(player.position) == null, "Zero chance spawns no target")
	combat.charge_target_chance = 1.0
	run.weapon_levels["gun"] = 2
	check(combat.try_spawn_charge_target(player.position) == null, "Below LV3 spawns no target")
	run.weapon_levels["gun"] = 3
	var monster = load("res://scenes/monster.tscn").instantiate()
	monster.player = player
	monster.max_health = 1.0
	monster.move_speed = 0.0
	game.add_child(monster)
	monster.global_position = player.global_position + Vector3(0, 0, -8)
	combat.deal_hit(monster, 10.0, "gun", true)
	var targets := get_nodes_in_group("gun_charge_targets")
	check(targets.size() == 1 and not combat.charge_ready, "Monster kill creates target without automatic charge")
	if targets.is_empty():
		quit(1)
		return
	var target = targets[0]
	var first_scale: float = target.scale.x
	await frames(30)
	check(target.remaining < 3.0 and target.scale.x < first_scale and target.scale.x > 0.0, "Target shrinks over time")
	player.head.rotation.x = atan2(target.global_position.y - combat.camera.global_position.y, 8.0)
	await frames(2)
	await capture("gun_red_charge_target")
	game.command_console.open_console()
	var remaining: float = target.remaining
	await create_timer(0.1, true).timeout
	check(is_equal_approx(target.remaining, remaining), "Target timer freezes during console pause")
	game.command_console.close_console()
	combat.cooldown = 0.0
	combat.gun_ammo = 12
	var xp: int = run.xp
	var points: int = game.get_node("Combo").points
	await mouse(true)
	await mouse(false)
	await frames(2)
	check(combat.charge_ready and not is_instance_valid(target), "Actually shooting target grants charge")
	check(run.xp == xp and game.get_node("Combo").points == points, "Target gives no monster XP/combo reward")
	await mouse(true)
	await frames(40)
	check(combat.charge_time >= 0.45, "Earned charge allows hold")
	await mouse(false)
	await frames(2)
	check(combat.empowered > 0.0 and not combat.charge_ready, "Release consumes one charge for original burst")
	combat.empowered = 0.0
	combat.cooldown = 0.0
	combat.gun_ammo = 12
	player.head.rotation = Vector3.ZERO
	await mouse(true)
	await frames(5)
	await mouse(false)
	check(combat.empowered == 0.0 and combat.charge_time == 0.0, "Charge cannot be reused after burst")
	var expired = combat.try_spawn_charge_target(player.global_position + Vector3(0, 0, -8))
	await frames(185)
	check(not is_instance_valid(expired) and not combat.charge_ready, "Missed target expires after 3 seconds")
	var removed = combat.try_spawn_charge_target(player.global_position + Vector3(0, 0, -8))
	combat.equip("sword")
	await frames(2)
	check(not is_instance_valid(removed) and not combat.charge_ready, "Switching weapons clears gun perk and target")
	if not failed:
		print("PASS: gun LV3 kill chance, shrinking 3s target, real shot acquisition, one-use charge, normal fire, expiry, pause and weapon switching")
	quit(1 if failed else 0)