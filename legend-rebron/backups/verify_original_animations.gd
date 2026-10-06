extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	current_scene = game
	await create_timer(0.3).timeout
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	for id in ["sword", "bow"]:
		combat.equip(id)
		await create_timer(0.2).timeout
		var view = combat.view
		var anim = view.animation_player
		assert(anim.current_animation == view.idle_animation)
		assert(anim.speed_scale == 1.0)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/original_" + id + "_idle.png")
		combat.cooldown = 0.0
		assert(combat.try_attack())
		assert(anim.current_animation == view.attack_animation)
		assert(anim.speed_scale == 1.0)
		var length = anim.get_animation(view.attack_animation).length
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/original_" + id + "_attack.png")
		await create_timer(length + 0.1).timeout
		assert(anim.current_animation == view.idle_animation)
		print("PASS original ", id, " skeleton, animation speed, attack and idle recovery; length=", length)
	quit()

