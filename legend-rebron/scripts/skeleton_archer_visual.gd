extends Node3D
const ROOT_PATH := "res://assets/monsters/skeleton_archer/"
const ROGUE = preload(ROOT_PATH + "Skeleton_Rogue.glb")
const CROSSBOW = preload(ROOT_PATH + "Skeleton_Crossbow.gltf")
const QUIVER = preload(ROOT_PATH + "Skeleton_Quiver.gltf")
const ANIMATIONS = preload(ROOT_PATH+"archer_animations.res")
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var weapon: Node3D
var shooting := false
var aiming := false
var dying := false
func _ready() -> void:
 var rogue = ROGUE.instantiate()
 rogue.name = "RogueAsset"
 rogue.scale = Vector3.ONE * 0.86
 rogue.rotation.y = PI
 add_child(rogue)
 skeleton = rogue.get_node("Rig_Medium/Skeleton3D")
 animation_player = AnimationPlayer.new()
 animation_player.name = "ArcherAnimation"
 rogue.add_child(animation_player)
 var library := ANIMATIONS.duplicate() as AnimationLibrary
 library.get_animation("Walking_B").loop_mode = Animation.LOOP_LINEAR
 animation_player.add_animation_library("",library)
 animation_player.animation_finished.connect(func(name):
  if name == &"Ranged_2H_Shoot": shooting = false
 )
 var hand := BoneAttachment3D.new()
 hand.name = "CrossbowHand"
 hand.bone_name = "handslot.r"
 skeleton.add_child(hand)
 weapon = CROSSBOW.instantiate()
 weapon.name = "Crossbow"
 weapon.scale = Vector3.ONE * 0.75
 weapon.rotation.y = PI * 0.5
 hand.add_child(weapon)
 var back := BoneAttachment3D.new()
 back.name = "QuiverBack"
 back.bone_name = "chest"
 skeleton.add_child(back)
 var quiver = QUIVER.instantiate()
 quiver.position = Vector3(0.2,0.12,-0.34)
 quiver.rotation.z = -0.2
 back.add_child(quiver)
 update_locomotion(false,2.2)
func _play(name: String, speed: float) -> void:
 animation_player.speed_scale = speed
 if animation_player.current_animation != name:
  animation_player.play(name,0.10)
func update_locomotion(moving: bool, speed: float) -> void:
 if dying or shooting or aiming:
  return
 if moving:
  _play("Walking_B",clampf(absf(speed)/2.2,0.6,2.5))
 else:
  _play("Ranged_2H_Aiming",1.0)
  animation_player.seek(animation_player.get_animation("Ranged_2H_Aiming").length,true)
  animation_player.speed_scale = 0.0
func aim(remaining: float, total: float) -> void:
 if dying or aiming:
  return
 aiming = true
 shooting = false
 var length: float = animation_player.get_animation("Ranged_2H_Aiming").length
 animation_player.play("Ranged_2H_Aiming",0.08)
 animation_player.speed_scale = length / maxf(total,0.01)
 animation_player.seek(length * clampf(1.0-remaining/maxf(total,0.01),0.0,1.0),true)
func release() -> void:
 if dying:
  return
 aiming = false
 shooting = true
 animation_player.speed_scale = 2.5
 animation_player.play("Ranged_2H_Shoot",0.03)
func cancel_aim() -> void:
 aiming = false
func die() -> void:
 dying = true
 shooting = false
 aiming = false
 animation_player.speed_scale = 1.0
 animation_player.play("Death_A",0.05)
func death_duration() -> float:
 return animation_player.get_animation("Death_A").length + 0.08
