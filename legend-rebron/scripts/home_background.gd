extends Control
const Style = preload("res://scripts/ui_style.gd")
@export var auto_cycle := true
@export var initial_stage := -1
@export var transition_duration := 0.65
const STAGES := ["grassland","desert","practice"]
const PATHS := ["res://scenes/grassland_arena.tscn","res://scenes/desert_arena.tscn","res://scenes/fps_arena.tscn"]
var views: Array[SubViewport] = []
var worlds: Array[Node3D] = []
var images: Array[TextureRect] = []
var actors: Array[CharacterBody3D] = []
var crowds: Array = []
var routes_by_world: Array = []
var arenas: Array[Node3D] = []
var cameras: Array[Camera3D] = []
var shot_starts: Array[Vector3] = []
var shot_ends: Array[Vector3] = []
var shot_targets: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var shot_length := 12.0
var spawn_timer := 6.0
var mouse_offset := Vector2.ZERO
var selected := -1
var cycle_time := 0.0
var transition: Tween
var stage_caption: Label
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 rng.randomize()
 for i in 3: _build_world(i)
 var shade := ColorRect.new()
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var material := ShaderMaterial.new()
 material.shader = preload("res://shaders/home_menu_shade.gdshader")
 shade.material = material
 add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _build_caption()
 select_world(initial_stage if initial_stage >= 0 and initial_stage < 3 else rng.randi_range(0,2),false)
func _build_world(index: int) -> void:
 var viewport := SubViewport.new()
 viewport.name = STAGES[index].capitalize()+"Preview"
 viewport.size = Vector2i(1280,720)
 viewport.own_world_3d = true
 viewport.gui_disable_input = true
 viewport.handle_input_locally = false
 viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
 add_child(viewport)
 var world := Node3D.new()
 viewport.add_child(world)
 var arena = load(PATHS[index]).instantiate()
 arena.name = "Arena"
 world.add_child(arena)
 var camera := Camera3D.new()
 world.add_child(camera)
 camera.fov = 65.0
 camera.position = Vector3(0,4.5,17)
 camera.look_at(Vector3(14,1.2,-12))
 camera.current = true
 var routes := [
  [Vector3(6,0,-3),Vector3(11,0,-5),Vector3(13,0,1),Vector3(7,0,3)],
  [Vector3(20,0,-5),Vector3(27,0,-6),Vector3(28,0,2),Vector3(20,0,3)],
  [Vector3(12,0,-17),Vector3(18,0,-18),Vector3(22,0,-12),Vector3(15,0,-10)],
  [Vector3(3,0,-12),Vector3(7,0,-13),Vector3(9,0,-8),Vector3(4,0,-7)]
 ]
 if index == 2:
  routes[2] = [Vector3(9,0,-20),Vector3(13,0,-21),Vector3(14,0,-15),Vector3(10,0,-14)]
 arenas.append(arena)
 cameras.append(camera)
 routes_by_world.append(routes)
 crowds.append([])
 shot_starts.append(camera.position)
 shot_ends.append(camera.position)
 shot_targets.append(Vector3(14,1.2,-12))
 var image := TextureRect.new()
 image.name = STAGES[index].capitalize()+"Background"
 image.texture = viewport.get_texture()
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_SCALE
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 image.modulate.a = 0.0
 add_child(image)
 image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 views.append(viewport)
 worlds.append(world)
 images.append(image)
func _build_caption() -> void:
 stage_caption = Style.label(self,"",13,Color("b7c0b7"))
 stage_caption.name = "StageCaption"
 stage_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 stage_caption.offset_left = -454
 stage_caption.offset_right = -36
 stage_caption.offset_top = -50
 stage_caption.offset_bottom = -26
 stage_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
func select_world(index: int, animated := true) -> void:
 if index == selected:
  cycle_time = 0.0
  return
 if is_instance_valid(transition): transition.kill()
 var previous := selected
 selected = index
 cycle_time = 0.0
 shot_length = rng.randf_range(11.0,15.0)
 spawn_timer = rng.randf_range(5.0,8.0)
 _plan_shot(index)
 _populate_crowd(index)
 stage_caption.text = GameData.STAGE_NAMES[STAGES[index]].to_upper()+"  /  LEGEND REBORN"
 for i in 3:
  images[i].modulate.a = 1.0 if i==previous else 0.0
  views[i].render_target_update_mode = SubViewport.UPDATE_ALWAYS if i==index or i==previous else SubViewport.UPDATE_DISABLED
  worlds[i].process_mode = Node.PROCESS_MODE_INHERIT if i==index or i==previous else Node.PROCESS_MODE_DISABLED
 if not animated or previous < 0:
  images[index].modulate.a = 1.0
  _finish_switch(index)
  return
 transition = create_tween()
 transition.set_parallel(true)
 transition.tween_property(images[index],"modulate:a",1.0,transition_duration)
 transition.tween_property(images[previous],"modulate:a",0.0,transition_duration)
 transition.chain().tween_callback(_finish_switch.bind(index))
func _finish_switch(index: int) -> void:
 if selected != index: return
 for i in 3:
  views[i].render_target_update_mode = SubViewport.UPDATE_ALWAYS if i==index else SubViewport.UPDATE_DISABLED
  worlds[i].process_mode = Node.PROCESS_MODE_INHERIT if i==index else Node.PROCESS_MODE_DISABLED
  images[i].modulate.a = 1.0 if i==index else 0.0
func _random_other_stage(current: int) -> int:
 return (current+rng.randi_range(1,2))%3

func _plan_shot(index: int) -> void:
 var starts := [Vector3(0,4.5,17),Vector3(4,3.2,11),Vector3(-2,4.0,13)]
 var targets := [Vector3(14,1.2,-12),Vector3(20,1.5,-9),Vector3(18,1.2,-12)]
 var choice := rng.randi_range(0,2)
 shot_starts[index] = starts[choice]
 shot_ends[index] = starts[choice]+Vector3(rng.randf_range(-0.6,0.6),rng.randf_range(-0.10,0.10),-0.6)
 shot_targets[index] = targets[choice]
 cameras[index].position = shot_starts[index]
 cameras[index].look_at(shot_targets[index])

func _populate_crowd(index: int) -> void:
 for actor in crowds[index]:
  if is_instance_valid(actor):
   actors.erase(actor)
   actor.queue_free()
 crowds[index].clear()
 var kinds := ["zombie","archer","flyer"]
 if rng.randf() < 0.40: kinds.append("golem")
 var count := rng.randi_range(5,7)
 while kinds.size() < count: kinds.append(_random_kind(index,kinds))
 # Shuffle using the backdrop's private RNG, preserving gameplay RNG/state.
 for i in range(kinds.size()-1,0,-1):
  var other := rng.randi_range(0,i)
  var value: String = kinds[i]
  kinds[i] = kinds[other]
  kinds[other] = value
 for kind in kinds: _spawn_actor(index,kind,false)

func _random_kind(index: int, pending: Array = []) -> String:
 var roll := rng.randf()
 var kind := "zombie" if roll < 0.40 else ("archer" if roll < 0.72 else ("flyer" if roll < 0.94 else "golem"))
 if kind == "golem":
  if pending.has("golem"): return "archer"
  for actor in crowds[index]:
   if is_instance_valid(actor) and actor.actor_kind == "golem": return "flyer"
 return kind

func _spawn_actor(index: int, kind: String = "", animate := true) -> CharacterBody3D:
 if kind.is_empty(): kind = _random_kind(index)
 if crowds[index].size() >= 8:
  var oldest = crowds[index].pop_front()
  actors.erase(oldest)
  if is_instance_valid(oldest):
   oldest.set_physics_process(false)
   var fade = oldest.create_tween()
   fade.tween_property(oldest,"scale",Vector3.ONE*0.1,0.35)
   fade.tween_callback(oldest.queue_free)
 var actor = preload("res://scripts/menu_actor.gd").new()
 actor.name = "Ambient"+kind.capitalize()
 actor.actor_kind = kind
 actor.arena = arenas[index]
 var route: Array = routes_by_world[index][rng.randi_range(0,3)]
 var variation := Vector3(rng.randf_range(-1.4,1.4),0,rng.randf_range(-1.0,1.0))
 for point in route: actor.route.append(point+variation)
 var start := rng.randi_range(0,3)
 actor.route_index = (start+1)%4
 actor.speed = rng.randf_range(0.85,1.25) if kind != "golem" else rng.randf_range(0.65,0.9)
 var point: Vector3 = actor.route[start]
 if arenas[index].has_method("ground_height"):
  point.y = arenas[index].ground_height(point.x,point.z)+0.05
 elif point.x >= 16 and point.x <= 36 and absf(point.z) <= 12: point.y = 2.05
 else: point.y = 0.05
 if kind == "flyer": point.y += 2.2
 actor.position = point
 worlds[index].add_child(actor)
 if animate:
  actor.scale = Vector3.ONE*0.1
  actor.create_tween().tween_property(actor,"scale",Vector3.ONE,0.45).set_trans(Tween.TRANS_SINE)
 crowds[index].append(actor)
 actors.append(actor)
 return actor

func _update_cameras(delta: float, cursor: Vector2) -> void:
 cursor.x = clampf(cursor.x,-1.0,1.0)
 cursor.y = clampf(cursor.y,-1.0,1.0)
 mouse_offset = mouse_offset.lerp(cursor,1.0-exp(-5.0*delta))
 for i in 3:
  if worlds[i].process_mode == Node.PROCESS_MODE_DISABLED: continue
  var progress := clampf(cycle_time/maxf(shot_length,0.1),0.0,1.0)
  var camera := cameras[i]
  var base := shot_starts[i].lerp(shot_ends[i],smoothstep(0.0,1.0,progress))
  camera.position = base+camera.basis.x*mouse_offset.x*0.20+Vector3.UP*(-mouse_offset.y)*0.12
  camera.look_at(shot_targets[i]+Vector3(mouse_offset.x*0.45,-mouse_offset.y*0.25,0))
  camera.rotation.z = 0.0

func _process(delta: float) -> void:
 cycle_time += delta
 if auto_cycle and cycle_time >= shot_length: select_world(_random_other_stage(selected))
 spawn_timer -= delta
 if selected >= 0 and spawn_timer <= 0.0:
  _spawn_actor(selected)
  spawn_timer = rng.randf_range(5.0,8.0)
 var cursor := get_viewport().get_mouse_position()/Vector2(get_viewport().get_visible_rect().size)*2.0-Vector2.ONE
 _update_cameras(delta,cursor)
