extends Node3D
const VFX = preload("res://scripts/magic_vfx.gd")
var radius := 3.5
var elapsed := 0.0
var materials: Array[ShaderMaterial] = []
var rune: MeshInstance3D
func _ready() -> void:
 rune = VFX.sprite(VFX.RUNE,radius*2.0,Color(VFX.BLUE,0.38),false)
 rune.rotation.x = -PI*0.5
 add_child(rune)
 var arena = get_tree().current_scene.get_node_or_null("Arena")
 var point := global_position
 var height := 0.03
 if arena != null and arena.has_method("ground_height"):
  var local: Vector3 = arena.to_local(point)
  height = arena.to_global(Vector3(local.x,arena.ground_height(local.x,local.z)+0.03,local.z)).y
 else:
  var excluded: Array[RID] = []
  for actor in get_tree().get_nodes_in_group("monsters"):
   if actor is CollisionObject3D: excluded.append(actor.get_rid())
  var owner_source = get_parent().source
  if is_instance_valid(owner_source): excluded.append(owner_source.player.get_rid())
  var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*4.0,point-Vector3.UP*12.0,1,excluded)
  var hit := get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty(): height = hit.position.y+0.03
 rune.global_position = Vector3(point.x,height,point.z)
 for strand in 3:
  var visual := MeshInstance3D.new()
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  for i in 80:
   var a := float(i)/80.0
   var b := float(i+1)/80.0
   var theta_a := a*TAU*2.0+float(strand)*TAU/3.0
   var theta_b := b*TAU*2.0+float(strand)*TAU/3.0
   var ra := radius*(0.10+a*0.48)
   var rb := radius*(0.10+b*0.48)
   var pa := Vector3(cos(theta_a)*ra,a*3.2-0.8,sin(theta_a)*ra)
   var pb := Vector3(cos(theta_b)*rb,b*3.2-0.8,sin(theta_b)*rb)
   var width := 0.07+0.09*a
   var vertices := [pa-Vector3.UP*width,pa+Vector3.UP*width,pb+Vector3.UP*width,pa-Vector3.UP*width,pb+Vector3.UP*width,pb-Vector3.UP*width]
   var uv := [Vector2(a,0),Vector2(a,1),Vector2(b,1),Vector2(a,0),Vector2(b,1),Vector2(b,0)]
   for j in 6:
    surface.set_uv(uv[j])
    surface.set_normal(Vector3.UP)
    surface.add_vertex(vertices[j])
  visual.mesh = surface.commit()
  var material := ShaderMaterial.new()
  material.shader = preload("res://shaders/magic_ribbon.gdshader")
  material.set_shader_parameter("tint",VFX.BLUE if strand%2==0 else VFX.PURPLE)
  material.set_shader_parameter("opacity",0.5)
  visual.material_override = material
  visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(visual)
  materials.append(material)
 var sparks = VFX.particles(VFX.BLUE,32,0.9,0.12)
 sparks.local_coords = true
 sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
 sparks.emission_ring_radius = radius*0.45
 sparks.emission_ring_inner_radius = radius*0.15
 sparks.emission_ring_height = 0.3
 sparks.direction = Vector3.UP
 sparks.initial_velocity_min = 1.5
 sparks.initial_velocity_max = 3.0
 sparks.emitting = true
 add_child(sparks)
func _process(delta: float) -> void:
 elapsed += delta
 var remaining: float = get_parent().remaining
 var fade := clampf(remaining/0.35,0.0,1.0)
 for material in materials:
  material.set_shader_parameter("phase",elapsed)
  material.set_shader_parameter("opacity",0.5*fade)
 rune.mesh.material.albedo_color.a = 0.38*fade
