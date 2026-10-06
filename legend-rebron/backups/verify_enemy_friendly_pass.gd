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
	var player = game.get_node("Player")
	player.run.set_physics_process(false)
	for kind in ["arrow","fireball"]:
		for wall_present in [false,true]:
			var ally = load("res://scenes/monster.tscn").instantiate()
			ally.player = player
			ally.position = player.global_position + Vector3(0,0.06,-3)
			game.add_child(ally)
			ally.set_physics_process(false)
			var shooter = load("res://scenes/archer_monster.tscn").instantiate()
			shooter.player = player
			shooter.position = player.global_position + Vector3(-0.45,0.06,-6)
			game.add_child(shooter)
			shooter.set_physics_process(false)
			var wall: StaticBody3D
			if wall_present:
				wall = StaticBody3D.new()
				wall.position = player.global_position + Vector3(0,1.5,-1.5)
				var collision := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(4,3,0.20)
				collision.shape = box
				wall.add_child(collision)
				game.add_child(wall)
			await physics_frame
			await physics_frame
			assert(shooter.can_fire() == not wall_present)
			var shot = load("res://scripts/enemy_projectile.gd").new()
			shot.player = player
			shot.kind = kind
			shot.gravity = 0.0
			shot.damage = 6.0
			shot.velocity = Vector3(0,0,20)
			shot.position = player.global_position + Vector3(0,1,-6)
			shot.excluded.assign([shooter.get_rid()])
			shot.source_position = shooter.global_position
			game.add_child(shot)
			shot.set_physics_process(false)
			var hp: float = player.run.current_health()
			shot._physics_process(0.4)
			assert(shot.is_queued_for_deletion())
			assert(ally.health == ally.max_health)
			assert(player.run.current_health() == (hp if wall_present else hp - 6.0))
			print("PASS ",kind," passes ally for aim/collision; wall=",wall_present," damage=",hp-player.run.current_health())
			ally.free()
			shooter.free()
			if wall_present:
				wall.free()
			await process_frame
	game.free()
	quit()
