extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_logo_delay_run.save"
 data.progress_path = "user://test_logo_delay_progress.cfg"
 var menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 current_scene = menu
 await create_timer(0.2).timeout
 var logo = menu.get_node("Center/Menu/Title")
 assert(logo is TextureRect and logo.texture is AtlasTexture)
 assert(logo.texture.atlas.resource_path.ends_with("BigGameLogo.png"))
 assert(logo.texture.region.size.x < 700)
 assert(menu.get_node("Center/Menu/Exit").get_global_rect().end.y < 720)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/big_logo_home_preview.png")
 menu.queue_free()
 await process_frame
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var player = game.get_node("Player")
 player.set_physics_process(false)
 var run = game.get_node("RunState")
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.set_physics_process(false)
 run.weapon_levels["spellbook"] = 5
 assert(combat.try_explosion())
 var effect = get_nodes_in_group("staff_explosions")[0]
 effect.set_physics_process(false)
 assert(is_equal_approx(effect.cast_duration,3.93))
 effect._physics_process(effect.FINAL_CLICK_TIME)
 assert(effect.hits_done==0)
 effect._physics_process(0.49)
 assert(effect.hits_done==0 and game.sfx.played["magic_explosion"]==0)
 effect._physics_process(0.011)
 assert(effect.hits_done==1 and game.sfx.played["magic_explosion"]==1)
 assert(effect.animation.current_animation_position>=effect.BLAST_ANIMATION_TIME)
 effect._physics_process(1.63)
 assert(effect.hits_done==10)
 var pause_ui = game.get_node("Interface/PauseOverlay")
 pause_ui.toggle_pause()
 await process_frame
 assert(pause_ui.menu.get_node("GameLogo").texture.atlas.resource_path.ends_with("BigGameLogo.png"))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://backups/big_logo_pause_preview.png")
 print("PASS: BigGameLogo on Home and Pause, no stretched canvas padding; final click + 0.5s triggers visual/sound/damage; ten hits preserved")
 game.queue_free()
 await process_frame
 quit()
