extends Node3D
const HEART_HEAL := 0.08
const SUPPLY_HEAL := 0.20
const SUPPLY_REFILL_SECONDS := 180.0
const HEART_LIFETIME := 15.0
const PICKUP_RADIUS := 1.5
const SUPPLY_RANGE := 3.0
var game: Node3D
var player: CharacterBody3D
var run: Node
var rng := RandomNumberGenerator.new()
var hearts: Array[Dictionary] = []
var supplies: Array[Dictionary] = []
var heart_mesh: ArrayMesh
var heart_material: StandardMaterial3D
var prompt: Label
var toast: Label
var toast_time := 0.0
var toast_amount := 0.0
var selected_supply := -1
var elapsed := 0.0
var chime: AudioStreamPlayer

func _ready() -> void:
 rng.randomize()
 player = game.get_node("Player")
 run = game.get_node("RunState")
 game.get_node("Player/Head/Camera3D/Combat").monster_defeated.connect(_on_monster_defeated)
 heart_mesh = _build_heart_mesh()
 heart_material = _material(Color("e95765"))
 heart_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 heart_material.emission_enabled = true
 heart_material.emission = Color("822b35")
 heart_material.emission_energy_multiplier = 0.25
 _build_ui()
 _build_supplies()

func _material(color: Color) -> StandardMaterial3D:
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 1.0
 return material

func _build_heart_mesh() -> ArrayMesh:
 var outline := PackedVector2Array([Vector2(0,-0.42),Vector2(-0.46,0.02),Vector2(-0.5,0.26),Vector2(-0.35,0.43),Vector2(-0.18,0.43),Vector2(0,0.23),Vector2(0.18,0.43),Vector2(0.35,0.43),Vector2(0.5,0.26),Vector2(0.46,0.02)])
 var indices := Geometry2D.triangulate_polygon(outline)
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for side in [-1.0,1.0]:
  for index in indices:
   var p := outline[index]
   surface.set_normal(Vector3(0,0,side))
   surface.add_vertex(Vector3(p.x,p.y,side*0.10))
 for i in outline.size():
  var p := outline[i]
  var q := outline[(i+1)%outline.size()]
  var a := Vector3(p.x,p.y,-0.10)
  var b := Vector3(q.x,q.y,-0.10)
  var c := Vector3(q.x,q.y,0.10)
  var d := Vector3(p.x,p.y,0.10)
  var normal := (b-a).cross(c-a).normalized()
  for vertex in [a,b,c,a,c,d]:
   surface.set_normal(normal)
   surface.add_vertex(vertex)
 return surface.commit()

func _build_ui() -> void:
 var layer := CanvasLayer.new()
 layer.layer = 12
 add_child(layer)
 prompt = Label.new()
 layer.add_child(prompt)
 prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 prompt.offset_left = -260
 prompt.offset_right = 260
 prompt.offset_top = 92
 prompt.offset_bottom = 124
 toast = Label.new()
 layer.add_child(toast)
 toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 toast.offset_left = -180
 toast.offset_right = 180
 toast.offset_top = -165
 toast.offset_bottom = -132
 for label in [prompt,toast]:
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  label.add_theme_font_size_override("font_size",20)
  label.add_theme_color_override("font_color",Color("bce4b5"))
  label.add_theme_color_override("font_outline_color",Color("152017"))
  label.add_theme_constant_override("outline_size",5)
  label.hide()
 chime = AudioStreamPlayer.new()
 chime.bus = "Effects"
 chime.volume_db = -23.0
 var sound := AudioStreamWAV.new()
 sound.format = AudioStreamWAV.FORMAT_16_BITS
 sound.mix_rate = 22050
 var bytes := PackedByteArray()
 bytes.resize(4410*2)
 for i in 4410:
  var t := float(i)/22050.0
  var sample := (sin(TAU*660.0*t)*0.6+sin(TAU*880.0*t)*0.4)*sin(PI*float(i)/4410.0)*exp(-t*12.0)
  bytes.encode_s16(i*2,int(sample*18000.0))
 sound.data = bytes
 chime.stream = sound
 add_child(chime)

func drop_chance() -> float:
 return 0.06 if run.current_health()/maxf(float(run.stats()["max_hp"]),1.0) < 0.30 else 0.03

func _on_monster_defeated(point: Vector3) -> void:
 if run.finished or get_tree().paused:
  return
 if rng.randf() < drop_chance():
  spawn_heart(_ground_point(point))

func _ground_point(point: Vector3) -> Vector3:
 var arena = game.get_node("Arena")
 if arena.has_method("ground_height"):
  var local: Vector3 = arena.to_local(point)
  local.y = arena.ground_height(local.x,local.z)+0.04
  return arena.to_global(local)
 var excluded: Array[RID] = [player.get_rid()]
 for monster in get_tree().get_nodes_in_group("monsters"):
  if monster is CollisionObject3D: excluded.append(monster.get_rid())
 var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*6.0,point-Vector3.UP*40.0,1,excluded)
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 return hit.position+Vector3.UP*0.04 if not hit.is_empty() else Vector3(point.x,0.04,point.z)

func spawn_heart(point: Vector3, lifetime := HEART_LIFETIME) -> Node3D:
 var root := Node3D.new()
 root.name = "HealingHeart"
 add_child(root)
 root.global_position = point
 var visual := MeshInstance3D.new()
 visual.name = "Heart"
 visual.mesh = heart_mesh
 visual.material_override = heart_material
 visual.position.y = 0.8
 root.add_child(visual)
 var label := Label3D.new()
 label.font = preload("res://assets/ui/fonts/Font.ttf")
 label.text = "+8% HP"
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 label.font_size = 32
 label.pixel_size = 0.003
 label.modulate = Color("ffd1d6")
 label.position.y = 1.4
 root.add_child(label)
 hearts.append({"node":root,"visual":visual,"label":label,"remaining":lifetime})
 return root

func _build_supplies() -> void:
 var points: Array[Vector3] = [Vector3(-25,0,-27),Vector3(43,0,37),Vector3(-38,0,43)]
 if game.stage_id == "desert": points = [Vector3(30,0,-23),Vector3(-31,0,29),Vector3(-28,0,-37)]
 elif game.stage_id == "practice": points = [Vector3(-18,0,8),Vector3(18,0,24),Vector3(0,0,-24)]
 var arena = game.get_node("Arena")
 for i in points.size():
  var point := points[i]
  if arena.get("obstacle_points") != null:
   for attempt in 8:
    var blocked := false
    for obstacle in arena.obstacle_points:
     if Vector2(point.x-obstacle.x,point.z-obstacle.z).length() < 2.8:
      blocked = true
      break
    if not blocked: break
    point += Vector3(2.0,0,1.0)
  _create_supply(i,_ground_point(point))

func _box(parent: Node3D, dimensions: Vector3, position_value: Vector3, material: Material) -> void:
 var visual := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = dimensions
 mesh.material = material
 visual.mesh = mesh
 visual.position = position_value
 parent.add_child(visual)

func _create_supply(index: int, point: Vector3) -> void:
 var body := StaticBody3D.new()
 body.name = "SupplyChest"+str(index+1)
 add_child(body)
 body.global_position = point
 var wood := _material(Color("826347"))
 var metal := _material(Color("c3b17e"))
 var medical := _material(Color("a6d29a"))
 _box(body,Vector3(1.6,0.65,1.1),Vector3(0,0.325,0),wood)
 for x in [-0.55,0.55]: _box(body,Vector3(0.10,0.67,1.13),Vector3(x,0.335,0),metal)
 for side in [-1.0,1.0]:
  _box(body,Vector3(0.18,0.40,0.025),Vector3(0,0.36,side*0.563),medical)
  _box(body,Vector3(0.43,0.16,0.025),Vector3(0,0.36,side*0.566),medical)
 var lid := Node3D.new()
 lid.position = Vector3(0,0.65,0.55)
 body.add_child(lid)
 _box(lid,Vector3(1.66,0.17,1.16),Vector3(0,0.08,-0.55),wood)
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(1.66,0.82,1.16)
 collision.shape = shape
 collision.position.y = 0.41
 body.add_child(collision)
 var label := Label3D.new()
 label.font = preload("res://assets/ui/fonts/Font.ttf")
 label.text = "SUPPLIES"
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 label.font_size = 32
 label.pixel_size = 0.003
 label.modulate = Color("c6e6bd")
 label.position.y = 1.25
 body.add_child(label)
 supplies.append({"node":body,"lid":lid,"label":label,"opened":false,"cooldown":0.0})

func can_collect() -> bool:
 return not run.finished and not get_tree().paused and player.input_enabled

func collect_heart(entry: Dictionary) -> float:
 if not can_collect() or entry["remaining"] <= 0.0 or not hearts.has(entry): return 0.0
 var root: Node3D = entry["node"]
 if not is_instance_valid(root): return 0.0
 var difference := player.global_position-root.global_position
 if Vector2(difference.x,difference.z).length() > PICKUP_RADIUS or absf(difference.y) > 1.8: return 0.0
 var amount: float = run.heal_fraction(HEART_HEAL)
 if amount > 0.0:
  hearts.erase(entry)
  root.queue_free()
  _show_heal(amount)
 return amount

func _supply_in_reach(index: int) -> bool:
 var root: Node3D = supplies[index]["node"]
 var target := root.global_position+Vector3.UP*0.5
 var offset: Vector3 = target-player.camera.global_position
 if offset.length() > SUPPLY_RANGE: return false
 if (-player.camera.global_basis.z).dot(offset.normalized()) < 0.75: return false
 var query := PhysicsRayQueryParameters3D.create(player.camera.global_position,target,1,[player.get_rid()])
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 return not hit.is_empty() and hit.collider == root

func open_supply(index: int) -> float:
 if not can_collect() or index < 0 or index >= supplies.size() or supplies[index]["opened"] or not _supply_in_reach(index): return 0.0
 var amount: float = run.heal_fraction(SUPPLY_HEAL)
 if amount > 0.0:
  supplies[index]["opened"] = true
  supplies[index]["cooldown"] = SUPPLY_REFILL_SECONDS
  _refresh_supply_label(supplies[index])
  _show_heal(amount)
 return amount

func _show_heal(amount: float) -> void:
 toast_amount = toast_amount+amount if toast_time > 0.3 else amount
 toast.text = "+%s HP" % run.catalog.format_number(toast_amount)
 toast_time = 1.1
 toast.show()
 chime.play()

func _unhandled_input(event: InputEvent) -> void:
 if can_collect() and event.is_action_pressed("interact") and not event.is_echo() and selected_supply >= 0:
  open_supply(selected_supply)
  get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
 if run.finished or get_tree().paused: return
 _advance_supplies(delta)
 elapsed += delta
 for entry in hearts.duplicate():
  entry["remaining"] -= delta
  var root: Node3D = entry["node"]
  if entry["remaining"] <= 0.0:
   hearts.erase(entry)
   root.queue_free()
   continue
  var visual: MeshInstance3D = entry["visual"]
  visual.position.y = 0.8+sin(elapsed*2.0)*0.05
  var facing := player.global_position-root.global_position
  if Vector2(facing.x,facing.z).length_squared() > 0.001:
   visual.rotation.y = atan2(facing.x,facing.z)
  root.scale = Vector3.ONE * (clampf(entry["remaining"]/2.0,0.0,1.0) if entry["remaining"] < 2.0 else 1.0)
  entry["label"].visible = root.global_position.distance_to(player.global_position) < 18.0
  collect_heart(entry)
 selected_supply = -1
 for i in supplies.size():
  var chest: Dictionary = supplies[i]
  chest["label"].position.y = 1.9 if chest["opened"] else 1.25
  chest["lid"].rotation.x = move_toward(chest["lid"].rotation.x,1.3 if chest["opened"] else 0.0,delta*4.0)
  chest["label"].visible = chest["node"].global_position.distance_to(player.global_position) < 18.0
  if not chest["opened"] and can_collect() and _supply_in_reach(i): selected_supply = i
 if selected_supply >= 0:
  prompt.text = "%s  OPEN SUPPLIES  /  +20%% HP" % GameData.key_label("interact") if run.damage_taken > 0.0 else "HEALTH FULL"
  prompt.show()
 else: prompt.hide()
 toast_time = maxf(0.0,toast_time-delta)
 toast.visible = toast_time > 0.0 and can_collect()

func _notification(what: int) -> void:
 if what == NOTIFICATION_PAUSED:
  selected_supply = -1
  if is_instance_valid(prompt): prompt.hide()
  if is_instance_valid(toast): toast.hide()
  if is_instance_valid(chime): chime.stop()

func capture_state() -> Dictionary:
 var saved_hearts: Array = []
 var opened: Array = []
 var cooldowns: Array = []
 for entry in hearts:
  if is_instance_valid(entry["node"]) and entry["remaining"] > 0.0:
   saved_hearts.append({"position":entry["node"].global_position,"remaining":entry["remaining"]})
 for chest in supplies:
  opened.append(chest["opened"])
  cooldowns.append(chest["cooldown"])
 return {"hearts":saved_hearts,"opened":opened,"cooldowns":cooldowns,"rng_seed":rng.seed,"rng_state":rng.state}

func restore_state(data: Dictionary) -> void:
 if data.is_empty(): return
 for entry in hearts:
  if is_instance_valid(entry["node"]): entry["node"].queue_free()
 hearts.clear()
 for i in supplies.size():
  var opened: bool = i < data.get("opened",[]).size() and bool(data["opened"][i])
  var remaining := SUPPLY_REFILL_SECONDS if opened else 0.0
  if i < data.get("cooldowns",[]).size():
   remaining = clampf(float(data["cooldowns"][i]),0.0,SUPPLY_REFILL_SECONDS)
  supplies[i]["cooldown"] = remaining
  supplies[i]["opened"] = remaining > 0.0
  supplies[i]["lid"].rotation.x = 1.3 if remaining > 0.0 else 0.0
  _refresh_supply_label(supplies[i])
 if data.has("rng_seed"): rng.seed = int(data["rng_seed"])
 if data.has("rng_state"): rng.state = int(data["rng_state"])
 for heart in data.get("hearts",[]):
  if float(heart.get("remaining",0.0)) > 0.0:
   spawn_heart(_ground_point(heart["position"]),float(heart["remaining"]))

func _exit_tree() -> void:
 if is_instance_valid(chime):
  chime.stop()
  chime.stream = null

func _advance_supplies(delta: float) -> void:
 if run.finished or get_tree().paused: return
 for chest in supplies:
  chest["cooldown"] = maxf(0.0,float(chest["cooldown"])-maxf(delta,0.0))
  chest["opened"] = chest["cooldown"] > 0.0
  _refresh_supply_label(chest)

func _refresh_supply_label(chest: Dictionary) -> void:
 var remaining := ceili(float(chest["cooldown"]))
 chest["label"].text = "REFILLS IN %02d:%02d" % [remaining/60,remaining%60] if remaining > 0 else "SUPPLIES"
 chest["label"].modulate = Color("ada99b") if remaining > 0 else Color("c6e6bd")
 chest["label"].position.y = 1.9 if remaining > 0 else 1.25
