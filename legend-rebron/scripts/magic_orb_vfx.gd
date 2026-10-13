extends Node3D
const VFX = preload("res://scripts/magic_vfx.gd")
var radius := 0.2
var purple := false
var elapsed := 0.0
var shell: ShaderMaterial
var rings: Array[MeshInstance3D] = []
var trail: CPUParticles3D
func _ready() -> void:
 var tint: Color = VFX.PURPLE if purple else VFX.BLUE
 var visual := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = radius
 sphere.height = radius*2.0
 sphere.radial_segments = 12 if preload("res://scripts/performance_profile.gd").quality()=="low" else 32
 sphere.rings = 8 if preload("res://scripts/performance_profile.gd").quality()=="low" else 16
 visual.mesh = sphere
 shell = ShaderMaterial.new()
 shell.shader = preload("res://shaders/magic_energy.gdshader")
 shell.set_shader_parameter("tint",tint)
 visual.material_override = shell
 visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(visual)
 var core := MeshInstance3D.new()
 var core_mesh := SphereMesh.new()
 core_mesh.radius = radius*0.30
 core_mesh.height = radius*0.60
 core_mesh.radial_segments = 12
 core_mesh.rings = 6
 core_mesh.material = VFX.material(Color(0.65,0.85,1.0,0.8))
 core.mesh = core_mesh
 core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(core)
 add_child(VFX.sprite(VFX.HALO,radius*4.5,Color(tint,0.25)))
 for i in 3:
  var ring = VFX.ring(radius*(1.12+float(i)*0.08),maxf(radius*0.025,0.008),Color(tint if i%2==0 else VFX.PURPLE,0.7))
  ring.rotation = Vector3(float(i)*0.8,0.0,float(i)*1.1)
  add_child(ring)
  rings.append(ring)
 trail = VFX.particles(tint,24,0.35,maxf(radius*0.45,0.10))
 trail.name = "ArcaneTrail"
 trail.direction = Vector3.BACK
 add_child(trail)
 trail.emitting = true
func _process(delta: float) -> void:
 elapsed += delta
 shell.set_shader_parameter("phase",elapsed)
 for i in rings.size():
  rings[i].rotation.y += delta*(1.7+float(i)*0.5)
  rings[i].rotation.z += delta*(0.8 if i%2==0 else -0.8)
func release_trail() -> void:
 if not is_instance_valid(trail): return
 trail.emitting = false
 var world = get_tree().current_scene
 trail.reparent(world,true)
 var fading = trail
 get_tree().create_timer(0.42,false).timeout.connect(fading.queue_free)
 trail = null
