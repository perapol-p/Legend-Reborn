extends Control
const COLORS = [Color("#ff5c9a"),Color("#ffd45d"),Color("#5de1ff"),Color("#a482ff"),Color("#67edb0"),Color("#ff965a")]
var particles: Array[Dictionary] = []
var elapsed := 10.0
var rng := RandomNumberGenerator.new()
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 rng.randomize()
 set_process(false)
func celebrate() -> void:
 particles.clear()
 elapsed = 0.0
 var count := 100 if preload("res://scripts/performance_profile.gd").quality()=="low" else 170
 for i in count:
  particles.append({"position":Vector2(rng.randf_range(0,size.x),size.y+rng.randf_range(0,45)),
   "velocity":Vector2(rng.randf_range(-240,240),rng.randf_range(-900,-640)),
   "angle":rng.randf_range(0,TAU),"spin":rng.randf_range(-9,9),
   "size":Vector2(rng.randf_range(4,7),rng.randf_range(8,15)),
   "color":COLORS[rng.randi_range(0,COLORS.size()-1)],"life":rng.randf_range(3.5,4.5)})
 set_process(true)
 queue_redraw()
func stop() -> void:
 particles.clear()
 elapsed = 10.0
 set_process(false)
 queue_redraw()
func _process(delta: float) -> void:
 if not is_visible_in_tree():
  stop()
  return
 elapsed += delta
 for particle in particles:
  particle["velocity"].y += 400.0*delta
  particle["position"] += particle["velocity"]*delta
  particle["angle"] += particle["spin"]*delta
  particle["life"] -= delta
 particles = particles.filter(func(p): return p["life"] > 0 and p["position"].y < size.y+100)
 queue_redraw()
 if particles.is_empty() and elapsed > 1.0: set_process(false)
func _draw() -> void:
 var flash := maxf(0,1.0-elapsed/0.65)*0.28
 if flash > 0: draw_rect(Rect2(Vector2(5,5),size-Vector2(10,10)),Color(1,0.8,0.35,flash),false,6)
 for particle in particles:
  var color: Color = particle["color"]
  color.a = clampf(particle["life"]/0.6,0.0,1.0)
  var width: Vector2 = particle["size"]
  draw_set_transform(particle["position"],particle["angle"],Vector2(0.35+0.65*absf(sin(elapsed*7+particle["angle"])),1))
  draw_rect(Rect2(-width*0.5,width),color)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
