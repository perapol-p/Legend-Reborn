extends Node3D
const ZOMBIE = preload("res://assets/monsters/zombie/zombie.fbx")
const TEXTURE = preload("res://assets/monsters/zombie/Texture.Zombie.png")
var animation_player: AnimationPlayer
var attacking := false
var dying := false
func _ready() -> void:
 var zombie = ZOMBIE.instantiate()
 zombie.name = "ZombieAsset"
 zombie.scale = Vector3.ONE * 1.12
 zombie.rotation.y = 0.0
 add_child(zombie)
 var material := StandardMaterial3D.new()
 material.albedo_texture = TEXTURE
 material.roughness = 0.9
 for mesh in zombie.find_children("*", "MeshInstance3D", true, false):
  mesh.material_override = material
 animation_player = zombie.find_child("AnimationPlayer", true, false) as AnimationPlayer
 assert(animation_player != null, "Zombie must have an AnimationPlayer")
 # Local copies keep looping and playback state independent for each enemy.
 for library_name in animation_player.get_animation_library_list():
  var library = animation_player.get_animation_library(library_name).duplicate()
  animation_player.remove_animation_library(library_name)
  if library.has_animation("Armature|Walk"):
   var walk = library.get_animation("Armature|Walk").duplicate()
   library.remove_animation("Armature|Walk")
   library.add_animation("Armature|Walk", walk)
  animation_player.add_animation_library(library_name, library)
 animation_player.get_animation("Armature|Walk").loop_mode = Animation.LOOP_LINEAR
 animation_player.animation_finished.connect(_on_animation_finished)
 update_locomotion(false, 2.6)
func update_locomotion(moving: bool, speed: float) -> void:
 if attacking or dying:
  return
 if animation_player.current_animation != "Armature|Walk":
  animation_player.play("Armature|Walk", 0.12)
 animation_player.speed_scale = clampf(speed / 2.6, 0.65, 2.5) if moving else 0.0
func attack() -> void:
 if dying:
  return
 attacking = true
 animation_player.speed_scale = 1.0
 animation_player.play("Armature|Attack", 0.08)
func die() -> void:
 dying = true
 animation_player.speed_scale = 1.0
 animation_player.play("Armature|Death", 0.06)
func _on_animation_finished(name: StringName) -> void:
 if name == &"Armature|Attack":
  attacking = false