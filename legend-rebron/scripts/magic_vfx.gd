extends RefCounted
const FLARE = preload("res://assets/vfx/kenney_particles/flare_01.png")
const HALO = preload("res://assets/vfx/kenney_particles/light_01.png")
const RUNE = preload("res://assets/vfx/kenney_particles/magic_03.png")
const TWIRL = preload("res://assets/vfx/kenney_particles/twirl_01.png")
const STAR = preload("res://assets/vfx/kenney_particles/star_01.png")
const BLUE := Color(0.22,0.66,1.0)
const PURPLE := Color(0.65,0.32,1.0)
static func material(tint: Color, texture: Texture2D = null) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 mat.albedo_color = tint
 mat.albedo_texture = texture
 return mat
static func sprite(texture: Texture2D, size_value: float, tint: Color, billboard := true) -> MeshInstance3D:
 var visual := MeshInstance3D.new()
 var quad := QuadMesh.new()
 quad.size = Vector2.ONE*size_value
 quad.material = material(tint,texture)
 if billboard:
  quad.material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
  quad.material.billboard_keep_scale = true
 visual.mesh = quad
 visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return visual
static func ring(radius: float, width: float, tint: Color) -> MeshInstance3D:
 var visual := MeshInstance3D.new()
 var torus := TorusMesh.new()
 torus.inner_radius = maxf(0.001,radius-width)
 torus.outer_radius = radius+width
 torus.rings = 16 if preload("res://scripts/performance_profile.gd").quality()=="low" else 32
 torus.ring_segments = 4 if preload("res://scripts/performance_profile.gd").quality()=="low" else 6
 torus.material = material(tint)
 visual.mesh = torus
 visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return visual
static func particles(tint: Color, amount: int, life: float, size_value: float, explosive := false) -> CPUParticles3D:
 var particles := CPUParticles3D.new()
 particles.amount = preload("res://scripts/performance_profile.gd").particle_count(amount)
 particles.lifetime = life
 particles.one_shot = explosive
 particles.explosiveness = 1.0 if explosive else 0.0
 particles.emitting = false
 particles.gravity = Vector3.ZERO
 particles.direction = Vector3.UP
 particles.spread = 180.0 if explosive else 35.0
 particles.initial_velocity_min = 1.2 if explosive else 0.2
 particles.initial_velocity_max = 4.0 if explosive else 0.8
 particles.scale_amount_min = 0.4
 particles.scale_amount_max = 1.0
 particles.local_coords = false
 var fade := Gradient.new()
 fade.set_color(0,Color(tint.lightened(0.3),0.85))
 fade.add_point(0.3,Color(tint,0.7))
 fade.set_color(1,Color(PURPLE,0.0))
 particles.color_ramp = fade
 var quad := QuadMesh.new()
 quad.size = Vector2.ONE*size_value
 var mat := material(Color.WHITE,STAR)
 mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
 mat.billboard_keep_scale = true
 mat.vertex_color_use_as_albedo = true
 quad.material = mat
 particles.mesh = quad
 particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return particles
static func burst(world: Node3D, point: Vector3, radius: float, purple := false) -> Node3D:
 var live = world.get_tree().get_nodes_in_group("magic_bursts").filter(func(node): return not node.is_queued_for_deletion())
 if live.size() >= (8 if preload("res://scripts/performance_profile.gd").quality()=="low" else 18): live[0].queue_free()
 var effect = load("res://scripts/magic_burst_vfx.gd").new()
 effect.radius = radius
 effect.purple = purple
 effect.position = world.to_local(point)
 world.add_child(effect)
 return effect
