extends CanvasLayer
signal transition_finished(path: String, error: int)
var busy := false
var cover: ColorRect
var material: ShaderMaterial
const DURATION := 0.60
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 layer = 500
 cover = ColorRect.new()
 add_child(cover)
 cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 cover.mouse_filter = Control.MOUSE_FILTER_STOP
 material = ShaderMaterial.new()
 material.shader = preload("res://shaders/menu_transition.gdshader")
 var gradient := Gradient.new()
 gradient.colors = PackedColorArray([Color.BLACK,Color.WHITE])
 var ramp := GradientTexture2D.new()
 ramp.gradient = gradient
 ramp.width = 256
 ramp.height = 1
 ramp.fill_from = Vector2.ZERO
 ramp.fill_to = Vector2(1,0)
 var image := Image.create(32,32,false,Image.FORMAT_RGBA8)
 for y in 32:
  for x in 32:
   var inside: bool = absf((x+0.5)/32.0-0.5) + absf((y+0.5)/32.0-0.5) < 0.48
   image.set_pixel(x,y,Color.WHITE if inside else Color.BLACK)
 material.set_shader_parameter("gradient_texture",ramp)
 material.set_shader_parameter("shape_texture",ImageTexture.create_from_image(image))
 material.set_shader_parameter("base_color",Color("111921"))
 material.set_shader_parameter("shape_tiling",22.0)
 material.set_shader_parameter("shape_feathering",0.08)
 material.set_shader_parameter("factor",0.0)
 cover.material = material
 cover.hide()
 get_viewport().size_changed.connect(_resize)
 _resize()
func _resize() -> void:
 material.set_shader_parameter("node_resolution",get_viewport().get_visible_rect().size)
func _input(_event: InputEvent) -> void:
 if busy: get_viewport().set_input_as_handled()
func _wipe(from: float, to: float) -> void:
 var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 tween.tween_method(func(value: float): material.set_shader_parameter("factor",value),from,to,DURATION)
 await tween.finished
func change_scene(path: String) -> void:
 if busy: return
 busy = true
 var previous_pause := get_tree().paused
 get_tree().paused = true
 cover.show()
 await _wipe(0.0,1.0)
 var error := get_tree().change_scene_to_file(path)
 if error == OK:
  await get_tree().process_frame
  await get_tree().process_frame
  get_tree().paused = true
 await _wipe(1.0,0.0)
 cover.hide()
 get_tree().paused = previous_pause if error != OK else false
 busy = false
 transition_finished.emit(path,error)
 if error != OK: push_error("Could not change scene: "+path)
