extends Node
var recording := false
var test_game: Node3D
var test_combat: Node
var test_spawner: Node
var measured_time := 0.0
var attack_clock := 0.0
var times: Array[float] = []
func _ready(): call_deferred("verify")
func verify():
 print("WEB_VALIDATION_STARTED")
 var root := get_tree().root
 var data = root.get_node("GameData")
 data.active_run_path = "user://web_validation_run.save"
 data.progress_path = "user://web_validation_progress.cfg"
 data.selected_stage = "practice"
 data.selected_character = "Wizard god"
 data.graphics_quality = "low"
 data.apply_settings()
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 get_tree().current_scene = game
 game.auto_pause_on_focus_loss = false
 var run = game.get_node("RunState")
 run.catalog.data["base_stats"]["max_hp"] = 1000000
 run.weapon_levels["spellbook"] = 5
 run.changed.emit()
 var player = game.get_node("Player")
 player.position = Vector3(0,0.04,0)
 var combat = player.get_node("Head/Camera3D/Combat")
 var spawner = game.get_node("MonsterSpawner")
 for i in 160:
  var kind := "monster" if i%8 < 5 else ("archer_monster" if i%8 < 7 else "flying_monster")
  var actor = load("res://scenes/"+kind+".tscn").instantiate()
  var angle := float(i)*TAU/160.0
  var distance := 8.0+float(i%6)*3.0
  actor.position = Vector3(cos(angle)*distance,2.2 if kind=="flying_monster" else 0.04,sin(angle)*distance)
  actor.player = player
  actor.max_health = 100000
  spawner.add_child(actor)
  spawner.monsters.append(actor)
 for position in [Vector3(3,1,3),Vector3(-3,1,3),Vector3(3,1,-3),Vector3(-3,1,-3)]:
  combat.spawn_tornado(position,1.0,3.5,30.0)
 combat.try_explosion()
 print("WEB_VALIDATION_ENEMIES_READY")
 test_game = game
 test_combat = combat
 test_spawner = spawner
 process_mode = Node.PROCESS_MODE_ALWAYS
 recording = true
func _process(delta: float) -> void:
 if not recording: return
 measured_time += delta
 if measured_time > 0.5: times.append(delta*1000.0)
 attack_clock += delta
 if attack_clock >= 0.35:
  test_combat.resolve_attack()
  attack_clock = 0.0
 if measured_time >= 6.0:
  recording = false
  times.sort()
  var total := 0.0
  for value in times: total += value
  print("WEB_VALIDATION_DONE enemy_count=",test_spawner.monsters.size()," average_fps=",1000.0/(total/times.size())," p95_frame_ms=",times[int(times.size()*0.95)]," paused=",get_tree().paused)
  test_game.process_mode = Node.PROCESS_MODE_DISABLED
