extends SceneTree
func _initialize(): call_deferred("inspect")
func inspect():
 var scene = load("res://assets/vfx/megumin_explosion/source/1.fbx").instantiate()
 root.add_child(scene)
 for node in scene.find_children("*","",true,false):
  if node is MeshInstance3D:
   print("MESH ",node.name," POSITION ",node.position," AABB ",node.get_aabb()," GLOBAL ",node.global_transform)
   for i in node.mesh.get_surface_count():
    var material = node.mesh.surface_get_material(i)
    print("MAT ",material.resource_name," ",material.albedo_texture.resource_path if material is StandardMaterial3D and material.albedo_texture != null else "NO ALBEDO")
  if node is AnimationPlayer:
   print("ANIM ",node.get_animation_list())
 scene.queue_free()
 await process_frame
 quit()
