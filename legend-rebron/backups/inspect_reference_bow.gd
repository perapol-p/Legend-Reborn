extends SceneTree
func _initialize():
	call_deferred("inspect")
func inspect():
	var model = load("res://assets/weapons/Hand_Bow.glb").instantiate()
	root.add_child(model)
	model.print_tree_pretty()
	var player = model.get_node("AnimationPlayer")
	for anim_name in player.get_animation_list():
		var anim = player.get_animation(anim_name)
		print("ANIMATION ", anim_name, " length=", anim.length, " tracks=", anim.get_track_count())
	player.play("Bow_idle")
	player.advance(0.0)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		print("MESH ",mesh.name," transform=",mesh.global_transform," aabb=",mesh.get_aabb())
	for skeleton in model.find_children("*", "Skeleton3D", true, false):
		for bone_name in ["carema", "hand_L", "hand_R", "Root"]:
			var bone = skeleton.find_bone(bone_name)
			if bone >= 0: print("BONE ",skeleton.get_path()," ",bone_name," ",skeleton.global_transform * skeleton.get_bone_global_pose(bone))
	quit()

