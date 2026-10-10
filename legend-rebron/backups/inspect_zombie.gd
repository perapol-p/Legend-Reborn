extends SceneTree
func _initialize():
 var scene = load("res://assets/monsters/zombie/zombie.fbx").instantiate()
 root.add_child(scene)
 inspect(scene)
 quit()
func inspect(node):
 if node is Node3D: print("NODE ",node.name," LOCAL ",node.transform)
 if node is MeshInstance3D:
  print("MESH ", node.get_path(), " AABB ",node.get_aabb(), " GLOBAL ",node.global_transform)
 if node is Skeleton3D:
  print("BONES ",node.get_bone_count())
  for i in range(mini(node.get_bone_count(),8)): print(node.get_bone_name(i), " ",node.get_bone_rest(i))
 if node is AnimationPlayer:
  for name in node.get_animation_list():
   var a = node.get_animation(name)
   print("ANIM ",name," LEN ",a.length," TRACKS ",a.get_track_count())
   for i in range(mini(a.get_track_count(),8)): print(a.track_get_path(i))
 for child in node.get_children(): inspect(child)