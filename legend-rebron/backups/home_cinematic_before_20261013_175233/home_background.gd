extends Control
const Style = preload("res://scripts/ui_style.gd")
const STAGES := ["grassland","desert","practice"]
const PATHS := ["res://scenes/grassland_arena.tscn","res://scenes/desert_arena.tscn","res://scenes/fps_arena.tscn"]
var views: Array[SubViewport] = []
var worlds: Array[Node3D] = []
var images: Array[TextureRect] = []
var buttons: Array[Button] = []
var zombies: Array[CharacterBody3D] = []
var selected := -1
var cycle_time := 0.0
var transition: Tween
var stage_caption: Label
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in 3: _build_world(i)
 var shade := ColorRect.new()
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var material := ShaderMaterial.new()
 material.shader = preload("res://shaders/home_menu_shade.gdshader")
 shade.material = material
 add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _build_selector()
 var index := STAGES.find(GameData.selected_stage)
 select_world(maxi(index,0),false)
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
 for z in 4:
  var zombie = preload("res://scripts/menu_zombie.gd").new()
  zombie.name = "WanderingZombie"+str(z+1)
  zombie.arena = arena
  zombie.route.assign(routes[z])
  zombie.route_index = (z+1)%4
  zombie.speed = 0.95+float(z)*0.12
  var point: Vector3 = routes[z][z%4]
  if arena.has_method("ground_height"):
   point.y = arena.ground_height(point.x,point.z)+0.05
  elif point.x >= 16 and point.x <= 36 and absf(point.z) <= 12:
   point.y = 2.05
  else: point.y = 0.05
  zombie.position = point
  world.add_child(zombie)
  zombies.append(zombie)
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
func _build_selector() -> void:
 var selector := VBoxContainer.new()
 selector.name = "WorldSelector"
 selector.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 selector.offset_left = -454
 selector.offset_right = -36
 selector.offset_top = -99
 selector.offset_bottom = -26
 selector.add_theme_constant_override("separation",8)
 add_child(selector)
 stage_caption = Style.label(selector,"",14,Color("d3d7cc"))
 stage_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 selector.add_child(row)
 for i in 3:
  var button := Style.button(row,GameData.STAGE_NAMES[STAGES[i]].to_upper(),select_world.bind(i))
  button.custom_minimum_size = Vector2(134,40)
  button.add_theme_font_size_override("font_size",13)
  buttons.append(button)
func select_world(index: int, animated := true) -> void:
 if index == selected:
  cycle_time = 0.0
  return
 if is_instance_valid(transition): transition.kill()
 var previous := selected
 selected = index
 cycle_time = 0.0
 var colors := [Color("9dbc86"),Color("d0b480"),Color("8eb4c9")]
 stage_caption.text = GameData.STAGE_NAMES[STAGES[index]].to_upper()+"  /  LEGEND REBORN"
 for i in 3:
  buttons[i].add_theme_stylebox_override("normal",Style.box(Color(0.08,0.12,0.15,0.85),colors[i] if i==index else Color("46535d"),8))
  images[i].modulate.a = 1.0 if i==previous else 0.0
  views[i].render_target_update_mode = SubViewport.UPDATE_ALWAYS if i==index or i==previous else SubViewport.UPDATE_DISABLED
  worlds[i].process_mode = Node.PROCESS_MODE_INHERIT if i==index or i==previous else Node.PROCESS_MODE_DISABLED
 if not animated or previous < 0:
  images[index].modulate.a = 1.0
  _finish_switch(index)
  return
 transition = create_tween()
 transition.set_parallel(true)
 transition.tween_property(images[index],"modulate:a",1.0,0.65)
 transition.tween_property(images[previous],"modulate:a",0.0,0.65)
 transition.chain().tween_callback(_finish_switch.bind(index))
func _finish_switch(index: int) -> void:
 if selected != index: return
 for i in 3:
  views[i].render_target_update_mode = SubViewport.UPDATE_ALWAYS if i==index else SubViewport.UPDATE_DISABLED
  worlds[i].process_mode = Node.PROCESS_MODE_INHERIT if i==index else Node.PROCESS_MODE_DISABLED
  images[i].modulate.a = 1.0 if i==index else 0.0
func _process(delta: float) -> void:
 cycle_time += delta
 if cycle_time >= 12.0: select_world((selected+1)%3)
