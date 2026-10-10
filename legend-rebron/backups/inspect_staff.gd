extends SceneTree
func _initialize():
 var scene = load("res://assets/weapons/Hand_Staff.glb").instantiate()
 inspect(scene,".")
 scene.free()
 quit()
func inspect(node, path):
 if node is Node3D: print("NODE ",path," ",node.transform)
 if node is MeshInstance3D: print("AABB ",node.get_aabb())
 if node is Skeleton3D:
  for i in node.get_bone_count():
   if node.get_bone_name(i) in ["Root","Bone","carema","hand_R","hand_L"]: print("BONE ",node.get_bone_name(i)," ",node.get_bone_rest(i))
 if node is AnimationPlayer:
  for name in node.get_animation_list(): print("ANIM ",name," ",node.get_animation(name).length)
 for child in node.get_children(): inspect(child,path+"/"+str(child.name))
