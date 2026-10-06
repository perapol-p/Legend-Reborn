extends Node3D
## Play the original GLB animation and skeleton without procedural changes.
@export var idle_animation: StringName
@export var attack_animation: StringName
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
var attacking := false

func _ready() -> void:
	for mesh in $Model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var library := animation_player.get_animation_library("").duplicate(true) as AnimationLibrary
	animation_player.remove_animation_library("")
	animation_player.add_animation_library("", library)
	animation_player.get_animation(idle_animation).loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation(attack_animation).loop_mode = Animation.LOOP_NONE
	animation_player.animation_finished.connect(_on_animation_finished)
	play_idle()
	animation_player.advance(0.0)

func play_idle() -> void:
	attacking = false
	animation_player.speed_scale = 1.0
	if animation_player.current_animation != idle_animation:
		animation_player.play(idle_animation, 0.0)

func play_attack(_duration: float) -> void:
	attacking = true
	animation_player.speed_scale = 1.0
	animation_player.play(attack_animation, 0.0)
	animation_player.seek(0.0, true)

func cancel_attack() -> void:
	if attacking:
		play_idle()

func _on_animation_finished(animation: StringName) -> void:
	if animation == attack_animation:
		play_idle()
