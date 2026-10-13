extends Node3D
const ASSET = preload("res://assets/monsters/golem/golem.glb")
var asset: Node3D
var animation_player: AnimationPlayer
var attacking := false
var dying := false
func _ready() -> void:
 asset = ASSET.instantiate()
 asset.name = "GolemAsset"
 asset.scale = Vector3.ONE*0.15
 asset.rotation.y = PI
 add_child(asset)
 animation_player = asset.find_child("AnimationPlayer",true,false) as AnimationPlayer
 for name in ["Idle","Walk"]:
  animation_player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
 animation_player.animation_finished.connect(func(name):
  if name == &"Attack3": attacking = false
 )
 update_locomotion(false,2.2)
func update_locomotion(moving: bool, speed: float) -> void:
 if attacking or dying: return
 var name := "Walk" if moving else "Idle"
 animation_player.speed_scale = clampf(speed/2.2,0.6,2.0) if moving else 1.0
 if animation_player.current_animation != name: animation_player.play(name,0.15)
func attack() -> void:
 if dying: return
 attacking = true
 var body = get_parent().get_parent()
 animation_player.speed_scale = animation_player.get_animation("Attack3").length / maxf(body.attack_interval*0.85,0.15)
 animation_player.play("Attack3",0.08)
func die() -> void:
 dying = true
 animation_player.stop()
 var tween := create_tween()
 tween.set_parallel(true)
 tween.tween_property(asset,"scale",Vector3.ONE*0.12,0.75)
 tween.tween_property(asset,"position:y",-0.45,0.75)
func death_duration() -> float:
 return 0.85
