extends Node3D
## Plays the baked arm and sword animations exported for Godot.
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

func _ready() -> void:
	for mesh in $Model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var library := animation_player.get_animation_library("").duplicate(true) as AnimationLibrary
	animation_player.remove_animation_library("")
	animation_player.add_animation_library("", library)
	animation_player.get_animation("Sword_idle").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("Sword_Swing").loop_mode = Animation.LOOP_NONE
	animation_player.animation_finished.connect(_on_animation_finished)
	play_idle()
	animation_player.advance(0.0)

func play_idle() -> void:
	animation_player.speed_scale = 1.0
	animation_player.play("Sword_idle", 0.08)

func play_attack(duration: float) -> void:
	animation_player.stop()
	animation_player.speed_scale = animation_player.get_animation("Sword_Swing").length / maxf(duration, 0.01)
	animation_player.play("Sword_Swing", 0.04)

func cancel_attack() -> void:
	play_idle()

func _on_animation_finished(animation: StringName) -> void:
	if animation == &"Sword_Swing":
		play_idle()
