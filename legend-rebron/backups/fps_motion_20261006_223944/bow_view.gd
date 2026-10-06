extends Node3D
## Plays the baked arm and bow animations exported for Godot.
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

func _ready() -> void:
	process_priority = 100
	for mesh in $Model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var library := animation_player.get_animation_library("").duplicate(true) as AnimationLibrary
	animation_player.remove_animation_library("")
	animation_player.add_animation_library("", library)
	animation_player.get_animation("Bow_idle").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("Bow_shoot").loop_mode = Animation.LOOP_NONE
	animation_player.animation_finished.connect(_on_animation_finished)
	play_idle()
	animation_player.advance(0.0)

func play_idle() -> void:
	animation_player.speed_scale = 1.0
	animation_player.play("Bow_idle", 0.08)

func play_attack(duration: float) -> void:
	animation_player.stop()
	animation_player.speed_scale = animation_player.get_animation("Bow_shoot").length / maxf(duration, 0.01)
	animation_player.play("Bow_shoot", 0.04)

func cancel_attack() -> void:
	play_idle()

func _on_animation_finished(animation: StringName) -> void:
	if animation == &"Bow_shoot":
		play_idle()

@onready var arms: Skeleton3D = $Model/Arm_Rig_001/Skeleton3D

func _process(_delta: float) -> void:
	# Keep the baked hand poses on the bow; fit the arm segments to FPS shoulders.
	for side in ["L", "R"]:
		var upper := arms.find_bone("upper_arm_" + side)
		var lower := arms.find_bone("lower_arm_" + side)
		var hand := arms.find_bone("hand_" + side)
		var hand_pose := arms.get_bone_global_pose_no_override(hand)
		var upper_pose := arms.get_bone_global_pose_no_override(upper)
		var lower_pose := arms.get_bone_global_pose_no_override(lower)
		var sign_x := -1.0 if side == "L" else 1.0
		var shoulder := Vector3(sign_x * 0.28, -0.30, 0.12)
		var wrist := to_local(arms.to_global(hand_pose.origin))
		var elbow := wrist + Vector3(sign_x * 0.20, -0.16, 0.20)
		var shoulder_local := arms.to_local(to_global(shoulder))
		var elbow_local := arms.to_local(to_global(elbow))
		var upper_length := arms.get_bone_rest(lower).origin.length()
		var lower_length := arms.get_bone_rest(hand).origin.length()
		arms.set_bone_global_pose_override(upper, _arm_segment(upper_pose, shoulder_local, elbow_local, upper_length), 1.0, true)
		arms.set_bone_global_pose_override(lower, _arm_segment(lower_pose, elbow_local, hand_pose.origin, lower_length), 1.0, true)
		arms.set_bone_global_pose_override(hand, hand_pose, 1.0, true)

func _arm_segment(source: Transform3D, start: Vector3, finish: Vector3, rest_length: float) -> Transform3D:
	var direction := finish - start
	var rotation := Basis(Quaternion(source.basis.y.normalized(), direction.normalized()))
	var basis := rotation * source.basis.orthonormalized()
	# Narrow the arm cross section without shrinking the hands.
	basis = basis.scaled_local(Vector3(0.95, direction.length() / maxf(rest_length, 0.001), 0.95))
	return Transform3D(basis, start)



