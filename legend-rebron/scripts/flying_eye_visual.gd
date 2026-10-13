extends Node3D
const ASSET = preload("res://assets/monsters/flying_eye/source/flying_eye_stand.fbx")
var asset: Node3D
var animation_player: AnimationPlayer
var dying := false
var recoil := 0.0
func _ready() -> void:
 asset = ASSET.instantiate()
 asset.name = "FlyingEyeAsset"
 asset.scale = Vector3.ONE*1.1
 asset.position = Vector3(0,1.25,0)
 asset.rotation.y = PI
 add_child(asset)
 animation_player = asset.find_child("AnimationPlayer",true,false) as AnimationPlayer
 animation_player.get_animation("fly").loop_mode = Animation.LOOP_LINEAR
 animation_player.play("fly")
func release() -> void:
 recoil = 0.22
func _process(delta: float) -> void:
 if dying: return
 recoil = maxf(0.0,recoil-delta)
 asset.position.z = sin((1.0-recoil/0.22)*PI)*0.10 if recoil > 0.0 else 0.0
func die() -> void:
 dying = true
 animation_player.stop()
 var tween := create_tween()
 tween.set_parallel(true)
 tween.tween_property(asset,"position:y",0.65,0.7)
 tween.tween_property(asset,"scale",Vector3.ONE*0.65,0.7)
func death_duration() -> float:
 return 0.8
