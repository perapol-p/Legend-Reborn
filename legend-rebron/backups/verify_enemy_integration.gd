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
	paused = false
	game.get_node("Interface/PauseOverlay").hide()
	var spawner = game.get_node("MonsterSpawner")
	spawner.set_physics_process(false)
	spawner.enabled = true
	spawner.survival_time = 600.0
	spawner.rng.seed = 531
	var counts := {"melee":0,"archer":0,"flyer":0}
	for i in 150:
		var monster = spawner.spawn_one()
		if monster == null:
			continue
		monster.set_physics_process(false)
		var type: String = "archer" if monster.is_in_group("archer_monsters") else ("flyer" if monster.is_in_group("flying_monsters") else "melee")
		counts[type] += 1
		assert(is_equal_approx(monster.health, 940.0 * (0.7 if type == "archer" else (0.6 if type == "flyer" else 1.0))))
		if type == "flyer":
			assert(monster.global_position.y > 2.0)
	assert(spawner.monsters.size() == 100)
	assert(counts["archer"] > 0 and counts["archer"] <= 12)
	assert(counts["flyer"] > 0 and counts["flyer"] <= 6)
	assert(spawner.spawn_one() == null)
	print("PASS real mixed spawn100, role HP, flight height, per-type caps; counts=",counts)
	spawner.reset_encounter()
	await process_frame
	var player = game.get_node("Player")
	var actors: Array[Node3D] = []
	for type in ["archer", "flyer"]:
		var scene = load("res://scenes/archer_monster.tscn" if type == "archer" else "res://scenes/flying_monster.tscn")
		var actor = scene.instantiate()
		actor.player = player
		actor.position = player.global_position + (Vector3(-2,0.08,-11) if type == "archer" else Vector3(-1.5,2.2,-5.5))
		actor.move_speed = 0.0
		game.add_child(actor)
		actors.append(actor)
	var wall := StaticBody3D.new()
	wall.position = player.global_position + Vector3(0,3.0,-2.5)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8,6,0.5)
	collision.shape = box
	wall.add_child(collision)
	game.add_child(wall)
	await physics_frame
	await physics_frame
	for actor in actors:
		actor.attack_timer = 0.0
		assert(not actor.can_fire())
	await create_timer(1.0).timeout
	for actor in actors:
		assert(actor.shots_fired == 0)
	wall.free()
	await physics_frame
	await physics_frame
	for actor in actors:
		assert(actor.can_fire())
		actor.attack_timer = 0.0
	game.get_node("Player/Head/Camera3D/Combat").view.hide()
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/new_enemy_types.png")
	var combat = player.get_node("Head/Camera3D/Combat")
	var kills: int = player.run.monsters_killed
	for actor in actors:
		combat.deal_hit(actor, 10000.0, "bow")
	assert(player.run.monsters_killed == kills + 2)
	print("PASS walls block ranged AI, charge telegraph visible, both new enemies damageable and count in summary")
	game.free()
	quit()

