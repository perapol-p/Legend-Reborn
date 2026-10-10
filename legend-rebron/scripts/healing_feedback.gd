extends Control
var player: CharacterBody3D
var run: Node
var border_material: ShaderMaterial
var icons: Array[Dictionary] = []
var flash_time := 0.0
var flash_duration := 0.9
var flash_strength := 0.0
var passive_cooldown := 0.0
var burst_cooldown := 0.0
var effects_started := 0
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var border := ColorRect.new()
 border.name = "HealingBorder"
 border.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(border)
 border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 border_material = ShaderMaterial.new()
 border_material.shader = preload("res://shaders/healing_vignette.gdshader")
 border.material = border_material
 hide()
func bind_player(body: CharacterBody3D) -> void:
 player = body
 run = player.run
 run.health_restored.connect(_on_healed)
 player.damage_received.connect(func(_amount, _position):
  # Let the red damage warning take priority if a hit arrives during healing.
  flash_time = minf(flash_time,0.08)
 )
func _on_healed(amount: float, burst: bool) -> void:
 if amount <= 0.0 or get_tree().paused or not is_instance_valid(run) or run.finished:
  return
 if not burst and passive_cooldown > 0.0: return
 effects_started += 1
 passive_cooldown = 4.0
 flash_duration = 0.9 if burst else 0.55
 flash_time = flash_duration
 var fraction := amount / maxf(float(run.stats()["max_hp"]),1.0)
 flash_strength = clampf(0.16+fraction*0.22,0.16,0.24) if burst else 0.055
 if not burst or burst_cooldown <= 0.0:
  var positions: Array = [0.20,0.31,0.69,0.80] if burst else [0.24,0.76]
  for i in positions.size():
   if icons.size() >= 12: icons.pop_front()
   icons.append({"x":positions[i],"y":0.86-float(i%2)*0.05,"age":-float(i)*0.04,"life":1.2 if burst else 0.9,"rise":145.0 if burst else 65.0,"size":(9.0+float(i%2)*2.0) if burst else 6.0,"alpha":0.8 if burst else 0.35})
  if burst: burst_cooldown = 0.12
 show()
 _update_border()
 queue_redraw()
func _process(delta: float) -> void:
 if not is_instance_valid(run): return
 if get_tree().paused or run.finished:
  flash_time = 0.0
  icons.clear()
  border_material.set_shader_parameter("strength",0.0)
  hide()
  return
 passive_cooldown = maxf(0.0,passive_cooldown-delta)
 burst_cooldown = maxf(0.0,burst_cooldown-delta)
 flash_time = maxf(0.0,flash_time-delta)
 for icon in icons: icon["age"] += delta
 icons = icons.filter(func(icon): return icon["age"] < icon["life"])
 _update_border()
 visible = flash_time > 0.0 or not icons.is_empty()
 if visible: queue_redraw()
func _update_border() -> void:
 var progress := clampf(1.0-flash_time/maxf(flash_duration,0.001),0.0,1.0)
 var fade := smoothstep(0.0,0.10,progress) * (1.0-smoothstep(0.20,1.0,progress))
 border_material.set_shader_parameter("strength",flash_strength*fade if flash_time > 0.0 else 0.0)
func _cross(center: Vector2, half_size: float, color: Color) -> void:
 var arm := half_size*0.34
 var polygon := PackedVector2Array([
  Vector2(-arm,-half_size),Vector2(arm,-half_size),Vector2(arm,-arm),Vector2(half_size,-arm),
  Vector2(half_size,arm),Vector2(arm,arm),Vector2(arm,half_size),Vector2(-arm,half_size),
  Vector2(-arm,arm),Vector2(-half_size,arm),Vector2(-half_size,-arm),Vector2(-arm,-arm)])
 for i in polygon.size(): polygon[i] += center
 draw_colored_polygon(polygon,color)
func _draw() -> void:
 for icon in icons:
  if icon["age"] < 0.0: continue
  var progress: float = clampf(icon["age"]/icon["life"],0.0,1.0)
  var alpha: float = smoothstep(0.0,0.12,progress)*(1.0-smoothstep(0.50,1.0,progress))*icon["alpha"]
  var center := Vector2(size.x*icon["x"],size.y*icon["y"]-progress*icon["rise"])
  var half_size: float = icon["size"]*(0.9+0.1*smoothstep(0.0,0.3,progress))
  _cross(center+Vector2(0,1.5),half_size+2.0,Color(0.03,0.16,0.08,alpha*0.4))
  _cross(center,half_size+4.0,Color(0.25,1.0,0.45,alpha*0.09))
  _cross(center,half_size,Color(0.45,1.0,0.58,alpha))
