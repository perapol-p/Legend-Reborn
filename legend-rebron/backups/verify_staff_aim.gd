extends SceneTree
class AimTarget extends StaticBody3D:
 var health := 10000.0
 var hits := 0
 func take_damage(amount: float) -> int:
  health -= amount
  hits += 1
  return 1
func _initialize(): call_deferred("verify")
func verify():
 create_timer(25,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_staff_aim.save"
 data.progress_path = "user://test_staff_aim_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.auto_pause_on_focus_loss = false
 var player = game.get_node("Player")
 player.set_physics_process(false)
 player.position = Vector3(50,25,50)
 var run = game.get_node("RunState")
 run.set_physics_process(false)
 var combat = player.get_node("Head/Camera3D/Combat")
 combat.set_physics_process(false)
 combat.view.animation_player.pause()
 for level in [1,2,3,4,5]:
  run.weapon_levels["spellbook"] = level
  for distance in [2.0,8.0,20.0]:
   player.rotation.y = 0.35
   player.head.rotation.x = 0.16
   var centre: Vector2 = player.camera.get_viewport().get_visible_rect().size*0.5
   var origin: Vector3 = player.camera.project_ray_origin(centre)
   var forward: Vector3 = player.camera.project_ray_normal(centre)
   var body := AimTarget.new()
   var shape := CollisionShape3D.new()
   var box := BoxShape3D.new()
   box.size = Vector3(0.18,0.4,0.18)
   shape.shape = box
   body.add_child(shape)
   game.add_child(body)
   body.global_position = origin+forward*distance
   body.rotation.y = 0.7
   await physics_frame
   var hit: Dictionary = combat.ray(origin,origin+forward*120)
   assert(not hit.is_empty() and hit["collider"]==body)
   var aim: Vector3 = combat.crosshair_target(120)
   assert(aim.distance_to(hit["position"])<0.001,"Aim must use exact centre ray intersection")
   var cast: Vector3 = combat.view.cast_position()
   combat.resolve_attack()
   var shots = get_nodes_in_group("weapon_projectiles")
   var shot = shots[-1]
   assert(shot.global_position.distance_to(cast)<0.001,"Must still launch from animated staff gem")
   assert(shot.direction.dot((aim-cast).normalized())>0.99999)
   # Isolate projectile accuracy from independently generated tornado damage.
   for tornado in get_nodes_in_group("weapon_tornadoes"):
    tornado.set_physics_process(false)
    tornado.queue_free()
   await create_timer(distance/22.0+0.08).timeout
   assert(body.hits==1,"Crosshair target must be hit once at LV %d / %.0fm (hits=%d)" % [level,distance,body.hits])
   for projectile in get_nodes_in_group("weapon_projectiles"): projectile.queue_free()
   for tornado in get_nodes_in_group("weapon_tornadoes"):
    tornado.set_physics_process(false)
    tornado.queue_free()
   body.queue_free()
   await process_frame
 # A solid wall between camera and staff must still block release.
 var wall := StaticBody3D.new()
 var collision := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(10,10,0.1)
 collision.shape = box
 wall.add_child(collision)
 game.add_child(wall)
 player.rotation = Vector3.ZERO
 player.head.rotation = Vector3.ZERO
 wall.global_position = player.camera.global_position+Vector3(0,0,-0.25)
 await physics_frame
 var shot = combat.fire_projectile("magic_wave",Vector3.FORWARD,16,22,0.15,false,0,player.camera.global_position+Vector3(0,0,-0.5))
 assert(shot.is_queued_for_deletion(),"Close wall must block the shot")
 print("PASS: exact centre aim and animated gem origin; small angled targets hit at 2/8/20m across LV1-5; walls still block")
 quit()
