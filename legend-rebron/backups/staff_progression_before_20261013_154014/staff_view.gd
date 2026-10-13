extends "res://scripts/fps_weapon_view.gd"
const VFX = preload("res://scripts/magic_vfx.gd")
var gem: Node3D
var rune: MeshInstance3D
var halo: MeshInstance3D
var sparks: CPUParticles3D
var cast_remaining := 0.0
var elapsed := 0.0
func _init() -> void:
 idle_animation = &"Idle"
 attack_animation = &"Attack"
func _ready() -> void:
 super._ready()
 var skeleton := $Model/Armature_Export/Skeleton3D as Skeleton3D
 var bone := skeleton.find_bone("Bone")
 var attachment := BoneAttachment3D.new()
 attachment.bone_name = "Bone"
 skeleton.add_child(attachment)
 gem = Node3D.new()
 gem.name = "ArcaneGem"
 gem.position = skeleton.get_bone_global_rest(bone).affine_inverse()*Vector3(0,2.30,0)
 attachment.add_child(gem)
 halo = VFX.sprite(VFX.HALO,1.15,Color(VFX.PURPLE,0.14))
 gem.add_child(halo)
 rune = VFX.sprite(VFX.RUNE,0.85,Color(VFX.BLUE,0.25))
 gem.add_child(rune)
 sparks = VFX.particles(VFX.BLUE,14,0.25,0.28,true)
 sparks.local_coords = true
 sparks.initial_velocity_min = 0.3
 sparks.initial_velocity_max = 1.6
 gem.add_child(sparks)
 var staff_mesh := $Model/Armature_Export/Skeleton3D/Staff_Export as MeshInstance3D
 var material = staff_mesh.mesh.surface_get_material(0).duplicate()
 material.emission_enabled = true
 material.emission = Color(0.35,0.12,0.65)
 material.emission_energy_multiplier = 0.6
 staff_mesh.set_surface_override_material(0,material)
func play_attack(duration: float) -> void:
 super.play_attack(duration)
 cast_remaining = 0.35
func release_magic() -> void:
 cast_remaining = 0.3
 sparks.restart()
 sparks.emitting = true
func cast_position() -> Vector3:
 return gem.global_position
func _process(delta: float) -> void:
 elapsed += delta
 cast_remaining = maxf(0.0,cast_remaining-delta)
 var pulse := cast_remaining/0.35
 halo.mesh.material.albedo_color.a = 0.14+pulse*0.4
 halo.scale = Vector3.ONE*(1.0+pulse*0.5)
 rune.mesh.material.albedo_color.a = 0.18+pulse*0.5
 rune.rotation.z += delta*(0.5+pulse*2.0)
 rune.scale = Vector3.ONE*(0.85+pulse*0.6)
 if is_instance_valid(get_parent()) and get_parent().get("run") != null and get_parent().run.finished:
  halo.hide()
  rune.hide()
  sparks.emitting = false
