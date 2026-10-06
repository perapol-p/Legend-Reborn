extends Node3D
## Uses the latest imported sword; supports exports with or without a swing clip.
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var model: Node3D = $Model
var swing_tween: Tween
var rest_transform: Transform3D

func _ready() -> void:
	rest_transform = model.transform
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.visible = mesh.name == "Arm" or mesh.name == "sword"
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var local_library := animation_player.get_animation_library("").duplicate(true) as AnimationLibrary
	animation_player.remove_animation_library("")
	animation_player.add_animation_library("", local_library)
	# Restore the exported arm pose before playing sword-only animation tracks.
	if animation_player.has_animation("FP_idle_pose"):
		animation_player.play("FP_idle_pose")
		animation_player.advance(0.0)
	_close_grip_fingers()
	animation_player.get_animation("Sword_idle").loop_mode = Animation.LOOP_LINEAR
	if animation_player.has_animation("Sword_Swing"):
		animation_player.get_animation("Sword_Swing").loop_mode = Animation.LOOP_NONE
	animation_player.animation_finished.connect(_on_animation_finished)
	_setup_grip_ik()
	play_idle()
	animation_player.advance(0.0)

func play_idle() -> void:
	animation_player.speed_scale = 1.0
	animation_player.play("Sword_idle", 0.08)

func play_attack(duration: float) -> void:
	cancel_attack()
	if animation_player.has_animation("Sword_Swing"):
		animation_player.stop()
		animation_player.speed_scale = animation_player.get_animation("Sword_Swing").length / maxf(duration, 0.01)
		animation_player.play("Sword_Swing", 0.04)
	else:
		# The latest export has idle only. Move the whole rig to keep the grip intact.
		var rest_rotation := rest_transform.basis.get_euler()
		swing_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		swing_tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		swing_tween.tween_property(model, "rotation", rest_rotation + Vector3(-0.25, -0.65, -0.85), duration * 0.4)
		swing_tween.tween_property(model, "position", rest_transform.origin + Vector3(-0.22, 0.02, -0.18), duration * 0.4)
		swing_tween.chain().tween_property(model, "rotation", rest_rotation, duration * 0.6)
		swing_tween.parallel().tween_property(model, "position", rest_transform.origin, duration * 0.6)

func cancel_attack() -> void:
	if swing_tween != null and swing_tween.is_valid():
		swing_tween.kill()
	model.transform = rest_transform
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
	# Put the shoulder origins behind the first-person camera, with the arms
	# facing forward independently of the decorative blade angle.
	var arm_rig: Node3D = $Model/Arm_Rig
	arm_rig.rotation.y = -1.2
	arm_rig.position = Vector3(0.471, 0.8, 1.212)
	for side in ["L", "R"]:
		var shoulder := arms.find_bone("upper_arm_" + side)
		var shoulder_rest := arms.get_bone_rest(shoulder)
		shoulder_rest.origin.x = 2.2 if side == "L" else -2.2
		shoulder_rest.origin.z = -4.5
		arms.set_bone_rest(shoulder, shoulder_rest)
		arms.set_bone_pose_position(shoulder, shoulder_rest.origin)
		for bone_name in ["lower_arm_" + side, "hand_" + side]:
			var bone := arms.find_bone(bone_name)
			var bone_rest := arms.get_bone_rest(bone)
			bone_rest.origin.y *= 2.0
			arms.set_bone_rest(bone, bone_rest)
			arms.set_bone_pose_position(bone, bone_rest.origin)
	_fit_arm_mesh_to_rest(arms)
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
		if not animation_player.has_animation(animation_name):
			continue
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
func _process(_delta: float) -> void:
	# Shoulders stay attached to the player while the sword rig swings.
	var arm_rig: Node3D = $Model/Arm_Rig
	arm_rig.global_transform = Transform3D(
		global_transform.basis * Basis(Vector3.UP, PI).scaled(Vector3.ONE * 0.1),
		to_global(Vector3(0.0, -0.15, -0.35))
	)
func _fit_arm_mesh_to_rest(arms: Skeleton3D) -> void:
	# Extend the source T-pose geometry with its rest bones, preserving hand size.
	var instance := arms.get_node("Arm") as MeshInstance3D
	var source := instance.mesh
	var fitted := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for index in vertices.size():
			var vertex := vertices[index]
			var side := 1.0 if vertex.x >= 0.0 else -1.0
			vertex.x += side * (1.2 + clampf(absf(vertex.x) - 1.003529, 0.0, 3.798198))
			vertex.z -= 4.5
			vertices[index] = vertex
		arrays[Mesh.ARRAY_VERTEX] = vertices
		fitted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		fitted.surface_set_material(surface, source.surface_get_material(surface))
	instance.mesh = fitted
	var skin := instance.skin.duplicate() as Skin
	for bind in skin.get_bind_count():
		var bone := arms.find_bone(skin.get_bind_name(bind))
		if bone >= 0:
			skin.set_bind_pose(bind, arms.get_bone_global_rest(bone).affine_inverse())
	instance.skin = skin