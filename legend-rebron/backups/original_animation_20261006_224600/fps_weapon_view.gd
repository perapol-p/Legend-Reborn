extends Node3D
## Compact camera-space weapon motion, preserving the exported hand poses.
@export var idle_animation: StringName
@export var attack_animation: StringName
@export var arm_path: NodePath
@export var is_bow := false
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var arms: Skeleton3D = get_node(arm_path)
@onready var model: Node3D = $Model
var rest_position: Vector3
var rest_rotation: Vector3
var attacking := false
var attack_time := 0.0
var attack_duration := 0.55
var motion_offset := Vector3.ZERO
var motion_rotation := Vector3.ZERO

func _ready() -> void:
	process_priority = 100
	rest_position = model.position
	rest_rotation = model.rotation
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
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
	animation_player.speed_scale = 0.65
	if animation_player.current_animation != idle_animation:
		animation_player.play(idle_animation, 0.10)

func play_attack(duration: float) -> void:
	attacking = true
	attack_time = 0.0
	attack_duration = maxf(duration, 0.01)
	# Keep the complete baked action, with a short blend instead of a hard stop.
	animation_player.speed_scale = animation_player.get_animation(attack_animation).length / attack_duration
	animation_player.play(attack_animation, 0.045)
	animation_player.seek(0.0, true)

func cancel_attack() -> void:
	if attacking:
		play_idle()

func _on_animation_finished(animation: StringName) -> void:
	if animation == attack_animation:
		play_idle()

func _process(delta: float) -> void:
	var offset := Vector3.ZERO
	var tilt := Vector3.ZERO
	if attacking:
		attack_time += delta
		var t := clampf(attack_time / attack_duration, 0.0, 1.0)
		# Brief anticipation, then a sharp follow-through and a softer recovery.
		var windup := sin(clampf(t / 0.25, 0.0, 1.0) * PI)
		var impact := exp(-maxf(t - 0.25, 0.0) * 10.0) if t >= 0.25 else 0.0
		if is_bow:
			offset = Vector3(0.012 * windup, -0.012 * impact, 0.025 * windup + 0.045 * impact)
			tilt = Vector3(-0.035 * impact, 0.0, -0.035 * windup)
		else:
			offset = Vector3(0.025 * windup - 0.035 * impact, -0.035 * impact, 0.025 * windup)
			tilt = Vector3(-0.06 * impact, 0.04 * windup, -0.07 * impact)
	var smoothing := 1.0 - exp(-delta * 24.0)
	motion_offset = motion_offset.lerp(offset, smoothing)
	motion_rotation = motion_rotation.lerp(tilt, smoothing)
	model.position = rest_position + motion_offset
	model.rotation = rest_rotation + motion_rotation
	_fit_forearms()

func _fit_forearms() -> void:
	for side in ["L", "R"]:
		var upper := arms.find_bone("upper_arm_" + side)
		var lower := arms.find_bone("lower_arm_" + side)
		var hand := arms.find_bone("hand_" + side)
		var hand_pose := arms.get_bone_global_pose_no_override(hand)
		var upper_pose := arms.get_bone_global_pose_no_override(upper)
		var lower_pose := arms.get_bone_global_pose_no_override(lower)
		var sign_x := -1.0 if side == "L" else 1.0
		var wrist := to_local(arms.to_global(hand_pose.origin))
		# Elbows exit below the screen instead of stretching toward fixed shoulders.
		var elbow := wrist + Vector3(sign_x * 0.065, -0.24, 0.16)
		var shoulder := elbow + Vector3(sign_x * 0.045, -0.25, 0.12)
		var elbow_local := arms.to_local(to_global(elbow))
		var shoulder_local := arms.to_local(to_global(shoulder))
		arms.set_bone_global_pose_override(upper, _arm_segment(upper_pose, shoulder_local, elbow_local, arms.get_bone_rest(lower).origin.length()), 1.0, true)
		arms.set_bone_global_pose_override(lower, _arm_segment(lower_pose, elbow_local, hand_pose.origin, arms.get_bone_rest(hand).origin.length()), 1.0, true)
		arms.set_bone_global_pose_override(hand, hand_pose, 1.0, true)

func _arm_segment(source: Transform3D, start: Vector3, finish: Vector3, rest_length: float) -> Transform3D:
	var direction := finish - start
	var rotation := Basis(Quaternion(source.basis.y.normalized(), direction.normalized()))
	var basis := rotation * source.basis.orthonormalized()
	basis = basis.scaled_local(Vector3(0.95, direction.length() / maxf(rest_length, 0.001), 0.95))
	return Transform3D(basis, start)

