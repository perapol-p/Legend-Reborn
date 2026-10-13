extends Node3D
const MODEL = preload("res://assets/vfx/megumin_explosion/source/1.fbx")
const SHADER = preload("res://shaders/megumin_explosion.gdshader")
const PLAYBACK_SPEED := 2.5
const IMPACT_TIME := 1.4
var source: Node
var age := 0.0
var damage := 0.0
var critical := false
var radius := 27.0
var damage_applied := false
var animation: AnimationPlayer
var materials: Array[ShaderMaterial] = []
func _ready() -> void:
 add_to_group("staff_explosions")
 var model := MODEL.instantiate()
 model.name = "MeguminExplosion"
 model.scale = Vector3.ONE * (radius * 2.2 / 9.0)
 add_child(model)
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  for i in mesh.mesh.get_surface_count():
   var original = mesh.mesh.surface_get_material(i)
   var id := clampi(int(original.resource_name),1,6)
   var material := ShaderMaterial.new()
   material.shader = SHADER
   material.set_shader_parameter("artwork",load("res://assets/vfx/megumin_explosion/textures/%d.jpeg" % id))
   mesh.set_surface_override_material(i,material)
   materials.append(material)
 animation = model.find_child("AnimationPlayer",true,false)
 animation.play("Scene")
 animation.pause()
 animation.seek(age*PLAYBACK_SPEED,true)
func _physics_process(delta: float) -> void:
 if not is_instance_valid(source) or source.run.finished:
  queue_free()
  return
 age += delta
 animation.seek(minf(age*PLAYBACK_SPEED,animation.get_animation("Scene").length),true)
 if not damage_applied and age >= IMPACT_TIME:
  damage_applied = true
  detonate()
 var duration: float = animation.get_animation("Scene").length/PLAYBACK_SPEED
 var fade := 1.0-smoothstep(duration-0.5,duration,age)
 for material in materials: material.set_shader_parameter("fade",fade)
 if age >= duration: queue_free()
func detonate() -> void:
 var centre := global_position+Vector3.UP*1.0
 var excluded: Array[RID] = [source.player.get_rid()]
 var space := get_world_3d().direct_space_state
 # All enemies in range can be hit; other enemies do not shield each other.
 for body in get_tree().get_nodes_in_group("monsters"):
  if not is_instance_valid(body) or body.dead: continue
  var point: Vector3 = body.aim_point()
  if centre.distance_to(point) > radius: continue
  var hit := preload("res://scripts/enemy_targeting.gd").ray_hit(space,centre,point,excluded.duplicate())
  if hit.is_empty(): source.deal_hit(body,damage,"spellbook",false,critical)
