extends SceneTree
func _initialize():
	call_deferred("inspect")
func inspect():
	var m=load("res://assets/weapons/Hand_Sword.glb").instantiate()
	root.add_child(m)
	var a=m.get_node("AnimationPlayer")
	a.play("Sword_idle")
	a.advance(0.3)
	var s=m.get_node("Arm_Rig/Skeleton3D")
	for i in s.get_bone_count():
		if "ctrl" in s.get_bone_name(i).to_lower() or "carema" in s.get_bone_name(i).to_lower(): print(i," ",s.get_bone_name(i)," ",s.get_bone_global_pose(i))
	var mesh=s.get_node("Arm")
	var skin=mesh.skin
	for i in skin.get_bind_count(): print("bind ",i," ",skin.get_bind_name(i))
	quit()