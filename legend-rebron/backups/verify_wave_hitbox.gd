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
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	combat.equip("sword")
	for level in [2, 3, 5]:
		var radius: float = maxf((0.4 if level == 2 else 1.05) * 2.2, 1.25)
		for angle in [0.0, 0.7]:
			var basis := Basis(Vector3.UP, angle)
			for side in [-1.0, 1.0]:
				for outside in [false, true]:
					var target = load("res://scenes/training_dummy.tscn").instantiate()
					target.max_health = 10000.0
					var box := BoxShape3D.new()
					box.size = Vector3(0.06, 0.08, 0.02)
					target.get_node("Collision").shape = box
					target.get_node("Collision").position = Vector3.ZERO
					game.add_child(target)
					var x: float = (radius + 0.10 if outside else radius * 0.95) * side
					target.global_position = Vector3(0, 20, 0) + basis * Vector3(x, -0.20, -4)
					await physics_frame
					await physics_frame
					var shot = combat.fire_projectile("sword_wave", basis * Vector3.FORWARD, 10.0, 600.0, 0.4 if level == 2 else 1.05, level == 5, 0.0, Vector3(0, 20, 0))
					shot.set_physics_process(false)
					shot._physics_process(1.0 / 60.0)
					assert((target.health < 10000.0) == not outside, "Edge collision LV%d side%f outside%s" % [level, side, outside])
					target.free()
					if is_instance_valid(shot) and not shot.is_queued_for_deletion():
						shot.queue_free()
					await process_frame
		print("PASS LV",level," both outer edges hit, outside misses, yaw rotation and high-speed sweep")
	quit()
