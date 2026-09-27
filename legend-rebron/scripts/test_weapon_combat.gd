extends Node
var game: Node
var combat: Node
var failed := false
func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + message)
func _ready() -> void:
	game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	add_child(game)
	await frames(12)
	combat = game.get_node("Player/Head/Camera3D/Combat")
	var player: CharacterBody3D = game.get_node("Player")
	var run: Node = game.get_node("RunState")
	var combo: Node = game.get_node("Combo")
	check(player.is_on_floor(), "Player remains on empty arena floor")
	check(not is_instance_valid(combat.dummy), "Arena starts without targets")
	var preview := OS.get_cmdline_user_args().has("--preview")
	for id in combat.ORDER:
		combat.equip(id)
		await frames(2)
		check(run.equipped_weapon_id == id, "Equipped state " + id)
		check(game.get_node("Interface/HUD").weapon_label.text.ends_with(run.weapon_name().to_upper()), "HUD " + id)
		combat.spawn_target()
		await frames(2)
		var target: Node3D = combat.dummy
		if preview:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://backups/weapon_" + id + ".png")
		if id in ["gun", "bow", "spellbook"]:
			target.global_position.z = player.global_position.z - 20.0
		await frames(2)
		combat.cooldown = 0.0
		check(combat.try_attack(), "Attack starts " + id)
		check(not combat.try_attack(), "Cooldown blocks repeated attack " + id)
		await frames(85)
		check(is_instance_valid(target) and target.health < 100.0, "Real hit at proper range " + id)
		print("PASS weapon ", id, " remaining HP ", target.health)
		target.queue_free()
		await frames(2)
	# A melee swing must miss targets outside its range.
	combat.equip("sword")
	combat.spawn_target()
	combat.dummy.position.z = player.position.z - 8.0
	await frames(2)
	combat.cooldown = 0.0
	combat.try_attack()
	await frames(40)
	check(combat.dummy.health == 100.0, "Melee range enforced")
	# A solid wall blocks both ray and projectile attacks.
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 4, 0.2)
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)
	wall.position = player.position + Vector3(0, 1.0, -1.0)
	for id in combat.ORDER:
		combat.equip(id)
		combat.spawn_target()
		await frames(3)
		combat.cooldown = 0.0
		combat.try_attack()
		await frames(55)
		check(combat.dummy.health == 100.0, "Wall blocks " + id)
	wall.queue_free()
	await frames(2)
	combat.equip("sword")
	combat.cooldown = 0.0
	player.input_enabled = false
	check(not combat.try_attack(), "Cursor release blocks attacks")
	player.input_enabled = true
	get_tree().paused = true
	check(not combat.try_attack(), "Pause blocks attacks")
	get_tree().paused = false
	# Switching during windup cancels that strike.
	combat.try_attack()
	combat.equip("gun")
	await frames(40)
	check(combat.dummy.health == 100.0, "Weapon switch cancels pending melee hit")
	# All damage uses current stats; no test-only damage shortcut.
	run.owned_ids.append("pencil")
	run.item_counts["pencil"] = 1
	combat.cooldown = 0.0
	combat.try_attack()
	await frames(3)
	check(combat.dummy.health <= 80.0, "ATK item increases gun damage")
	check(combo.points > 0, "Hits feed combo")
	# Target behind the shooter must not take melee damage.
	combat.equip("katana")
	combat.spawn_target()
	combat.dummy.position.z = player.position.z + 2.0
	await frames(3)
	combat.cooldown = 0.0
	combat.try_attack()
	await frames(30)
	check(combat.dummy.health == 100.0, "Melee forward arc enforced")
	# A kill grants XP once, even with duplicate hits in the same frame.
	combat.equip("gun")
	combat.spawn_target()
	await frames(3)
	combat.dummy.health = 1.0
	var xp_before: int = run.xp
	var doomed: Node = combat.dummy
	combat.cooldown = 0.0
	combat.try_attack()
	combat.deal_hit(doomed, 50.0)
	check(run.xp == xp_before + 3, "Kill grants XP exactly once")
	await frames(3)
	check(not is_instance_valid(doomed), "Dead target removed")
	print("WEAPON INTEGRATION ", "FAILED" if failed else "PASSED")
	get_tree().quit(1 if failed else 0)

