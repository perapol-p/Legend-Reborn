extends SceneTree
var strikes := 0
func _initialize(): call_deferred("verify")
func block(world: Node3D, at: Vector3, dimensions: Vector3) -> StaticBody3D:
 var body := StaticBody3D.new()
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = dimensions
 shape.shape = box
 body.add_child(shape)
 body.position = at
 world.add_child(body)
 return body
func verify():
 create_timer(35).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_climbing.save"
 data.progress_path = "user://test_climbing_progress.cfg"
 for stage in data.STAGES:
  data.selected_stage = stage
  var screen = load("res://scenes/character_select.tscn").instantiate()
  root.add_child(screen)
  var background = screen.get_node("SelectedStageBackground")
  assert(background.selected == data.STAGES.find(stage))
  assert(not background.auto_cycle)
  assert(screen.get_child(0) == background)
  screen.queue_free()
  await process_frame
 print("PASS: character background matches all three selected maps")
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.auto_pause_on_focus_loss = false
 var player = game.get_node("Player")
 player.set_physics_process(false)
 game.get_node("RunState").set_physics_process(false)
 # Use a clear patch of the existing floor, away from ramps/covers.
 var ledge := block(game,Vector3(50,1.5,47),Vector3(6,3,6))
 player.position = Vector3(50,3.04,47)
 var zombie = load("res://scenes/monster.tscn").instantiate()
 zombie.player = player
 zombie.position = Vector3(50,0.04,52)
 game.add_child(zombie)
 var hp: float = game.get_node("RunState").current_health()
 var highest := 0.0
 var saw_climb := false
 for i in 420:
  await physics_frame
  highest = maxf(highest,zombie.position.y)
  saw_climb = saw_climb or zombie.climbing
  if game.get_node("RunState").current_health() < hp: break
 assert(saw_climb and highest > 2.9,"Zombie must climb the 3m ledge")
 assert(game.get_node("RunState").current_health() < hp,"Zombie must hit player on ledge")
 print("PASS: zombie climbs 3m obstacle and attacks elevated player")
 zombie.queue_free()
 ledge.queue_free()
 await physics_frame
 # A stationary living monster acts as a physical climbing support.
 player.position = Vector3(50,3,42)
 var support = load("res://scenes/monster.tscn").instantiate()
 support.position = Vector3(50,0.04,47)
 game.add_child(support)
 support.set_physics_process(false)
 var climber = load("res://scenes/monster.tscn").instantiate()
 climber.player = player
 climber.position = Vector3(50,0.04,49)
 game.add_child(climber)
 highest = 0.0
 for i in 150:
  await physics_frame
  highest = maxf(highest,climber.position.y)
 assert(highest > 1.6,"Monster must climb another monster")
 print("PASS: monsters can climb other living monsters")
 climber.queue_free()
 support.queue_free()
 await physics_frame
 # Archer must approach/climb a ledge that blocks its shot.
 ledge = block(game,Vector3(50,1.5,47),Vector3(6,3,6))
 player.position = Vector3(50,3.04,47)
 var archer = load("res://scenes/archer_monster.tscn").instantiate()
 archer.player = player
 archer.position = Vector3(50,0.04,52)
 game.add_child(archer)
 saw_climb = false
 for i in 240:
  await physics_frame
  saw_climb = saw_climb or archer.climbing
 assert(saw_climb,"Archer must climb when the elevated target is hidden")
 print("PASS: archer approaches and climbs obstructed elevated target")
 archer.queue_free()
 ledge.queue_free()
 await physics_frame
 # No climbing through a solid overhead ceiling.
 var wall := block(game,Vector3(50,1.5,47),Vector3(6,3,1))
 var ceiling := block(game,Vector3(50,2.06,49),Vector3(6,0.2,5))
 climber = load("res://scenes/monster.tscn").instantiate()
 climber.player = player
 climber.position = Vector3(50,0.04,47.92)
 game.add_child(climber)
 climber.set_physics_process(false)
 await physics_frame
 climber.velocity = Vector3(0,0,-2.6)
 climber.apply_climbing(1.0/60.0)
 assert(not climber.climbing,"Solid overhead ceiling must prevent climbing")
 print("PASS: climbing respects overhead collisions")
 game.queue_free()
 await process_frame
 print("ALL CLIMBING AND CHARACTER BACKGROUND CHECKS PASSED")
 quit()
