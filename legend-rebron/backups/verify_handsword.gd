extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	root.add_child(game)
	await create_timer(0.3).timeout
	var combat = game.get_node("Player/Head/Camera3D/Combat")
	combat.equip("sword")
	await create_timer(0.3).timeout
	var anim = combat.view.animation_player
	assert(anim.current_animation == "Sword_idle")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/handsword_idle.png")
	combat.cooldown = 0.0
	assert(combat.try_attack())
	assert(anim.current_animation == "Sword_Swing" or (combat.view.swing_tween != null and combat.view.swing_tween.is_running()))
	await create_timer(0.18).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://backups/handsword_swing.png")
	await create_timer(0.6).timeout
	assert(anim.current_animation == "Sword_idle")
	print("PASS handsword idle, swing, return to idle")
	quit()