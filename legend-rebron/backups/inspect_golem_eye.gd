extends SceneTree
func _initialize(): call_deferred("inspect_models")
func inspect_models():
 for file in ["res://assets/monsters/golem/golem.glb","res://assets/monsters/flying_eye/source/flying_eye_stand.fbx"]:
  var node = load(file).instantiate()
  root.add_child(node)
  print("FILE ",file)
  inspect(node,".")
  node.free()
 quit()
func inspect(node,path):
 if node is Node3D: print("NODE ",path," ",node.transform)
 if node is MeshInstance3D:
  print("BOUNDS ",node.get_aabb()," GLOBAL ",node.global_transform)
 if node is Skeleton3D:
  print("BONE_COUNT ",node.get_bone_count())
 if node is AnimationPlayer:
  print("ROOT ",node.root_node)
  for name in node.get_animation_list(): print("ANIM ",name," ",node.get_animation(name).length)
 for child in node.get_children(): inspect(child,path+"/"+str(child.name))
