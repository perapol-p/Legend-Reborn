extends Node3D
const VFX = preload("res://scripts/magic_vfx.gd")
var radius := 1.0
var purple := false
var elapsed := 0.0
var rings: Array[MeshInstance3D] = []
var flare: MeshInstance3D
var sprites: Array[MeshInstance3D] = []
func _ready() -> void:
 add_to_group("magic_bursts")
 var tint: Color = VFX.PURPLE if purple else VFX.BLUE
 for i in 2:
  var ring = VFX.ring(1.0,0.015,Color(tint,0.7))
  ring.rotation.x = PI*0.5 if i==1 else 0.0
  ring.scale = Vector3.ONE*0.05
  add_child(ring)
  rings.append(ring)
 flare = VFX.sprite(VFX.FLARE,minf(radius*2.5,3.5),Color(tint.lightened(0.25),0.65))
 add_child(flare)
 sprites.append(flare)
 var rune = VFX.sprite(VFX.RUNE,minf(radius*2.0,5.0),Color(tint,0.6))
 rune.rotation.x = -PI*0.5
 rune.mesh.material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
 rune.position.y = 0.05
 add_child(rune)
 sprites.append(rune)
 var sparks = VFX.particles(tint,24 if radius < 3.0 else 40,0.5,0.13 if radius < 3.0 else 0.2,true)
 sparks.initial_velocity_min = minf(radius,2.0)
 sparks.initial_velocity_max = minf(radius*3.0,8.0)
 add_child(sparks)
 sparks.emitting = true
func _process(delta: float) -> void:
 elapsed += delta
 if elapsed >= 0.65:
  queue_free()
  return
 var progress := elapsed/0.65
 var fade := (1.0-progress)*(1.0-progress)
 for i in rings.size():
  var size_value := radius*(0.12+0.88*sqrt(progress))*(1.0 if i==0 else 0.65)
  rings[i].scale = Vector3.ONE*size_value
  rings[i].mesh.material.albedo_color.a = fade*0.65
 for i in sprites.size():
  sprites[i].mesh.material.albedo_color.a = fade*(0.6 if i==0 else 0.38)
  sprites[i].rotation.z += delta*0.8 if i==0 else 0.0
