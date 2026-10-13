extends SceneTree
func _initialize(): call_deferred("verify")
func frame(name: String) -> Image:
 await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 image.save_png("res://backups/"+name+".png")
 return image
func difference(a: Color,b: Color) -> float:
 return absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
func verify():
 create_timer(20,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_full_screen_shake.save"
 data.progress_path = "user://test_full_screen_shake_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.auto_pause_on_focus_loss = false
 var player = game.get_node("Player")
 await create_timer(0.15).timeout
 # Freeze the displayed scene for a pixel comparison of world, hand and HUD.
 game.process_mode = Node.PROCESS_MODE_DISABLED
 var baseline: Image = await frame("screen_shake_before")
 var aim: Vector3 = player.head.rotation
 player.shake_camera(0.06,0.16)
 player._process(0.016)
 assert(player.screen_shake.visible and player.screen_shake.shift.length()>1.0)
 assert(player.head.rotation.is_equal_approx(aim))
 assert(player.camera.h_offset==0.0 and player.camera.v_offset==0.0)
 player.screen_shake.set_screen_offset(Vector2(8,6))
 var shifted: Image = await frame("screen_shake_after")
 # Each region must match the same translation, including HUD, scenery and hand.
 for region in [Rect2i(40,28,260,100),Rect2i(420,330,350,190),Rect2i(970,320,220,260)]:
  var error := 0.0
  var samples := 0
  for y in range(region.position.y,region.end.y,4):
   for x in range(region.position.x,region.end.x,4):
    error += difference(shifted.get_pixel(x,y),baseline.get_pixel(x+8,y+6))
    samples += 1
  assert(error/float(samples)<0.035,"Entire rendered region must shift, including world and HUD: "+str(region))
 player._process(0.20)
 assert(not player.screen_shake.visible and player.screen_shake.shift == Vector2.ZERO)
 game.process_mode = Node.PROCESS_MODE_INHERIT
 player.shake_camera(0.06,0.16)
 player._process(0.016)
 paused = true
 assert(not player.screen_shake.visible and player.screen_shake.shift == Vector2.ZERO)
 paused = false
 print("PASS: whole-frame pixel translation in HUD/world/weapon regions, aim unchanged, exact reset and pause cleanup")
 quit()
