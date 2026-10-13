extends SceneTree
func _initialize(): call_deferred("inspect_pose")
func inspect_pose():
 for file in ["res://assets/monsters/golem/golem.glb","res://assets/monsters/flying_eye/source/flying_eye_stand.fbx"]:
  var asset = load(file).instantiate()
  root.add_child(asset)
  var anim = asset.find_child("AnimationPlayer",true,false)
  anim.play("Idle" if "golem" in file else "fly")
  anim.advance(0.0)
  for mesh in asset.find_children("*","MeshInstance3D",true,false):
   var skeleton = mesh.get_node_or_null(mesh.skeleton)
   if not skeleton is Skeleton3D or mesh.skin == null: continue
   var matrices: Array[Transform3D] = []
   for i in mesh.skin.get_bind_count():
    var bone: int = mesh.skin.get_bind_bone(i)
    if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(i))
    matrices.append(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(i))
   var minimum := Vector3(INF,INF,INF)
   var maximum := Vector3(-INF,-INF,-INF)
   for surface in mesh.mesh.get_surface_count():
    var arrays = mesh.mesh.surface_get_arrays(surface)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var bones = arrays[Mesh.ARRAY_BONES]
    var weights = arrays[Mesh.ARRAY_WEIGHTS]
    var count: int = bones.size()/vertices.size()
    for v in vertices.size():
     var point := Vector3.ZERO
     for w in count:
      var weight: float = weights[v*count+w]
      if weight > 0.0: point += (matrices[int(bones[v*count+w])]*vertices[v])*weight
     point = skeleton.global_transform*point
     minimum = minimum.min(point)
     maximum = maximum.max(point)
   print(file," ",mesh.name," POSED_MIN ",minimum," POSED_MAX ",maximum)
  asset.free()
 quit()
