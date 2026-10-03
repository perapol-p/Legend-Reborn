extends Node3D
## The imported rig animates both hands and sword together.
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

func _ready() -> void:
	for mesh in $Model.find_children("*", "MeshInstance3D", true, false):
		# Blender rig control shapes are exported alongside the render meshes.
		mesh.visible = mesh.name == "Arm" or mesh.name == "sword"
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var local_library := animation_player.get_animation_library("").duplicate(true) as AnimationLibrary
	animation_player.remove_animation_library("")
	animation_player.add_animation_library("", local_library)
	_close_grip_fingers()
	animation_player.get_animation("Sword_idle").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("Sword_Swing").loop_mode = Animation.LOOP_NONE
	animation_player.animation_finished.connect(_on_animation_finished)
	_setup_grip_ik()
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
	if animation_player.current_animation == "Sword_Swing":
		play_idle()

func _on_animation_finished(animation: StringName) -> void:
	if animation == &"Sword_Swing":
		play_idle()
func _setup_grip_ik() -> void:
	# The source GLB contains unbaked Blender arm constraints. Recreate the
	# two hand targets on the animated sword bone so the exported rig can grip it.
	var sword_skeleton: Skeleton3D = $Model/Armature/Skeleton3D
	var arms: Skeleton3D = $Model/Arm_Rig/Skeleton3D
	var grip := BoneAttachment3D.new()
	grip.bone_name = "handle_root"
	sword_skeleton.add_child(grip)
	for side in ["L", "R"]:
		var target := Node3D.new()
		grip.add_child(target)
		target.position = Vector3(-0.55 if side == "R" else 0.55, 0.30 if side == "R" else -0.35, -0.15)
		target.rotation = Vector3(0.0, 0.0, -PI / 2.0 if side == "R" else PI / 2.0)
		var ik := SkeletonIK3D.new()
		ik.root_bone = "upper_arm_" + side
		ik.tip_bone = "hand_" + side
		ik.override_tip_basis = true
		ik.use_magnet = true
		ik.magnet = Vector3(-3.0 if side == "R" else 3.0, -2.0, 0.5)
		arms.add_child(ik)
		ik.target_node = ik.get_path_to(target)
		ik.start()
func _close_grip_fingers() -> void:
	for animation_name in ["Sword_idle", "Sword_Swing"]:
		var library := animation_player.get_animation_library("")
		var animation := animation_player.get_animation(animation_name).duplicate() as Animation
		library.remove_animation(animation_name)
		library.add_animation(animation_name, animation)
		for track in animation.get_track_count():
			var path := str(animation.track_get_path(track))
			if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D or not "finger" in path:
				continue
			var bend := 0.65 if "_01_" in path else 1.25
			for key in animation.track_get_key_count(track):
				var rotation: Quaternion = animation.track_get_key_value(track, key)
				animation.track_set_key_value(track, key, rotation * Quaternion(Vector3.RIGHT, bend))