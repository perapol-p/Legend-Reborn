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
	combat.equip("bow")
	await create_timer(0.3).timeout
	var anim = combat.view.animation_player
	assert(anim.current_animation == "Bow_idle")
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/new_bow_idle.png")
	var shots = combat.projectiles_fired
	combat.cooldown = 0.0
	assert(combat.try_attack())
	assert(anim.current_animation == "Bow_shoot")
	await create_timer(0.25).timeout
	assert(combat.projectiles_fired > shots)
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://backups/new_bow_shoot.png")
	await create_timer(0.7).timeout
	assert(anim.current_animation == "Bow_idle")
	combat.equip("sword")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/right_sword_idle.png")
	combat.cooldown = 0.0
	assert(combat.try_attack())
	assert(combat.view.animation_player.current_animation == "Sword_Swing")
	await create_timer(0.16).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/new_sword_action.png")
	await create_timer(0.55).timeout
	assert(combat.view.animation_player.current_animation == "Sword_idle")
	for i in 3:
		combat.cooldown = 0.0
		assert(combat.try_attack())
		await create_timer(0.65).timeout
		assert(combat.view.animation_player.current_animation == "Sword_idle")
	combat.view.cancel_attack()
	var idle_time = combat.view.animation_player.current_animation_position
	combat.view.cancel_attack()
	assert(combat.view.animation_player.current_animation_position == idle_time)
	combat.equip("bow")
	assert(combat.view.animation_player.current_animation == "Bow_idle")
	print("PASS FPS bow projectile, sword repeated swings, idle recovery, cancel and switching")
	quit()



