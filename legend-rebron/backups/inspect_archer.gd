extends SceneTree
func _initialize():
 for file in ["Skeleton_Rogue.glb","Rig_Medium_CombatRanged.glb","Skeleton_Crossbow.gltf","Skeleton_Quiver.gltf"]:
  var scene = load("res://assets/monsters/skeleton_archer/"+file).instantiate()
  print("FILE ",file)
  inspect(scene,".")
  scene.free()
 quit()
func inspect(node, path):
 if node is Node3D: print("NODE ",path," ",node.transform)
 if node is Skeleton3D:
  for i in node.get_bone_count(): print("BONE ",node.get_bone_name(i)," REST ",node.get_bone_rest(i))
 if node is MeshInstance3D: print("BOUNDS ",node.get_aabb())
 if node is AnimationPlayer:
  print("ROOT ",node.root_node)
  for name in ["Ranged_2H_Aiming","Ranged_2H_Shoot"]:
   if node.has_animation(name):
    var anim = node.get_animation(name)
    print("ANIM ",name," ",anim.length)
    for i in mini(6,anim.get_track_count()): print("TRACK ",anim.track_get_path(i))
 for child in node.get_children(): inspect(child,path+"/"+str(child.name))