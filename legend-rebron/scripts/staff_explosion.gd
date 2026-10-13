extends Node3D
const MODEL = preload("res://assets/vfx/megumin_explosion/source/1.fbx")
const SHADER = preload("res://shaders/megumin_explosion.gdshader")
const PLAYBACK_SPEED := 2.5
const IMPACT_TIME := 3.0
const CHARGE_ANIMATION_TIME := 3.5
const HIT_COUNT := 10
const HIT_INTERVAL := 0.18
var source: Node
var age := 0.0
var damage := 0.0
var critical := false
var radius := 27.0
var damage_applied := false
var hits_done := 0
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
 animation.seek(animation_time(age),true)
func _physics_process(delta: float) -> void:
 if not is_instance_valid(source) or source.run.finished:
  queue_free()
  return
 age += delta
 animation.seek(minf(animation_time(age),animation.get_animation("Scene").length),true)
 while hits_done < HIT_COUNT and age >= IMPACT_TIME+float(hits_done)*HIT_INTERVAL:
  source.player.shake_camera(0.06,0.16)
  hits_done += 1
  damage_applied = true
  detonate()
 var duration: float = IMPACT_TIME+(animation.get_animation("Scene").length-CHARGE_ANIMATION_TIME)/PLAYBACK_SPEED
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
  var hit: Dictionary = source.world_obstruction(centre,point)
  if hit.is_empty(): source.deal_hit(body,damage/float(HIT_COUNT),"spellbook",false,critical)

# Stretch only the charge phase; keep the actual blast fast and forceful.
func animation_time(time: float) -> float:
 if time < IMPACT_TIME:
  return time/IMPACT_TIME*CHARGE_ANIMATION_TIME
 return CHARGE_ANIMATION_TIME+(time-IMPACT_TIME)*PLAYBACK_SPEED
