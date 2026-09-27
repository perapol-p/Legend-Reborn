extends Node
var failed := false
var game: Node
var run: Node
var hud: Node
var combat: Node
var player: CharacterBody3D
var targets: Array[Node] = []
func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + message)
func target_at(offset: Vector3) -> Node3D:
	var target: Node3D = load("res://scenes/training_dummy.tscn").instantiate()
	target.max_health = 10000.0
	game.add_child(target)
	target.global_position = player.global_position + offset
	targets.append(target)
	return target
func clear_effects() -> void:
	combat.attack_held = false
	combat.empowered = 0.0
	combat.charge_time = 0.0
	combat.volley_queue.clear()
	combat.pending = -1.0
	for node in get_tree().get_nodes_in_group("weapon_projectiles") + get_tree().get_nodes_in_group("weapon_tornadoes"):
		node.queue_free()
	for target in targets:
		if is_instance_valid(target):
			target.queue_free()
	targets.clear()
	player.respawn()
	player.input_enabled = true
	combat.cooldown = 0.0
	combat.special_cooldown = 0.0
	combat.gun_ammo = 12
	combat.gun_reload = 0.0
	combat.bow_ammo = 4
	combat.bow_reload = 0.0
	await frames(3)
func _ready() -> void:
	game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	add_child(game)
	await frames(10)
	run = game.get_node("RunState")
	hud = game.get_node("Interface/HUD")
	player = game.get_node("Player")
	combat = player.get_node("Head/Camera3D/Combat")
	var previews := OS.get_cmdline_user_args().has("--preview")
	if OS.get_cmdline_user_args().has("--ui-only"):
		combat.equip("gun")
		for i in range(3):
			hud.weapon_upgrade_button.pressed.emit()
		await frames(3)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/upgrade_button_ready.png")
		print("UPGRADE UI PREVIEW PASSED")
		get_tree().quit()
		return
	for id in combat.ORDER:
		combat.equip(id)
		check(run.weapon_level() == 1, "Each weapon starts at LV1: " + id)
		var previous_cooldown: float = combat.attack_cooldown()
		for level in range(1, 6):
			if level > 1:
				hud.weapon_upgrade_button.pressed.emit()
			check(run.weapon_level() == level, "Upgrade button: " + id + str(level))
			check(hud.weapon_level_label.text.contains("LV %d / 5" % level), "Level label")
			check(not hud.weapon_ability_label.text.is_empty(), "Ability description")
			await clear_effects()
			var target := target_at(Vector3(0, 0, -8 if id == "sword" and level >= 2 else -2.6))
			var nearby: Node3D
			if id == "gun" and level == 5:
				nearby = target_at(Vector3(1.5, 0, -2.6))
			await frames(3)
			var shots: int = combat.projectiles_fired
			var tornadoes: int = combat.tornadoes_created
			check(combat.try_attack(), "Attack starts")
			await frames(60)
			if previews and level == 5:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://backups/upgrade_" + id + ".png")
			await frames(15)
			check(target.health < 10000, "Actual damage " + id + " LV" + str(level))
			match id:
				"sword":
					check(combat.projectiles_fired - shots == (0 if level == 1 else 1), "Sword wave unlock")
					if level >= 4:
						check(combat.attack_cooldown() < previous_cooldown, "Rapid waves grow faster")
				"katana":
					var expected := 0 if level == 1 else (15 if level == 5 else (4 if level == 4 else 1))
					check(combat.tornadoes_created - tornadoes == expected, "Katana tornadoes/rounds")
				"gun":
					if level == 2:
						check(combat.attack_cooldown() < previous_cooldown, "Gun fire rate increases")
					if level >= 4:
						check(combat.rpg_ready, "Target hit earns RPG")
						check(combat.try_special(), "RPG launches")
						check(not combat.rpg_ready, "RPG consumed")
					if level == 5:
						check(nearby.health < 10000, "Explosive bullet hurts nearby target")
				"bow":
					var expected := 1 if level == 1 else (3 if level == 2 else (6 if level == 3 else 12))
					check(combat.projectiles_fired - shots == expected, "Bow arrow count")
				"spellbook":
					check(combat.tornadoes_created - tornadoes == (1 if level >= 3 else 0), "Spell tornado")
					if level == 5:
						check(combat.projectiles_fired - shots == 4, "Nuke plus three spells at once")
			previous_cooldown = combat.attack_cooldown()
		check(hud.weapon_upgrade_button.disabled, "MAX button disabled")
		check(not run.upgrade_weapon(), "Model enforces LV5 cap")
		print("PASS 5 levels: ", id)
	await clear_effects()
	# U really routes through the input action and does not alter player level.
	run.weapon_levels["sword"] = 1
	combat.equip("sword")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_U
	key.keycode = KEY_U
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	check(run.weapon_level() == 2, "U shortcut upgrades")
	key.pressed = false
	Input.parse_input_event(key)
	await frames(2)
	combat.equip("bow")
	check(run.weapon_level() == 5, "Other weapon levels retained")
	check(run.level == 1 and run.xp == 0, "Player level unaffected")
	# Piercing arrows hit two targets in a line.
	await clear_effects()
	combat.equip("bow")
	var front := target_at(Vector3(0, 0, -3))
	var rear := target_at(Vector3(0, 0, -6))
	await frames(3)
	combat.try_attack()
	await frames(35)
	check(front.health < 10000 and rear.health < 10000, "Piercing arrows hit both targets")
	combat.bow_ammo = 0
	combat.bow_reload = 1.0
	await frames(2)
	check(combat.bow_reload == 0 and combat.bow_ammo == 4, "LV5 bow has no reload")
	# Charged gun powers up rate/damage while consuming no ammunition.
	await clear_effects()
	combat.equip("gun")
	var gun_target := target_at(Vector3(0, 0, -3))
	await frames(3)
	combat.charge_time = 1.0
	var ammo: int = combat.gun_ammo
	combat.release_charge()
	await frames(12)
	check(combat.empowered > 0 and combat.gun_ammo == ammo, "Charged burst consumes no ammo")
	check(gun_target.health < 9970, "Charged burst actually fires repeatedly")
	# Tornado pulls a moving monster in, without teleporting through walls.
	await clear_effects()
	var monster: CharacterBody3D = load("res://scenes/monster.tscn").instantiate()
	monster.player = player
	monster.move_speed = 0
	monster.max_health = 10000
	game.add_child(monster)
	monster.position = player.position + Vector3(2, 0, -6)
	targets.append(monster)
	var center := player.position + Vector3(0, 1.2, -6)
	var before := Vector2(monster.position.x - center.x, monster.position.z - center.z).length()
	combat.spawn_tornado(center, 1, 4, 2)
	await frames(30)
	var after := Vector2(monster.position.x - center.x, monster.position.z - center.z).length()
	print("TORNADO distance ", before, " -> ", after, " health ", monster.health)
	check(after < before - 0.4 and monster.health < 10000, "Tornado pulls and damages monsters")
	# Warp moves through clear ground, not through a solid wall.
	await clear_effects()
	combat.equip("spellbook")
	var start := player.position
	check(combat.try_special(), "Warp activates")
	check(player.position.distance_to(start) > 7.0, "Warp travels eight metres")
	await clear_effects()
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 5, 0.3)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	wall.position = player.position + Vector3(0, 1, -2)
	await frames(3)
	start = player.position
	combat.try_special()
	check(player.position.distance_to(start) < 2, "Warp cannot pass through walls")
	wall.queue_free()
	await clear_effects()
	run.weapon_levels["sword"] = 2
	combat.equip("sword")
	get_tree().paused = true
	hud.weapon_upgrade_button.pressed.emit()
	check(run.weapon_level() == 2, "Cannot upgrade while paused")
	get_tree().paused = false
	print("REFERENCE WEAPON UPGRADE ", "FAILED" if failed else "PASSED")
	get_tree().quit(1 if failed else 0)

