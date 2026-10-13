extends SceneTree
func _initialize(): call_deferred("inspect")
func inspect():
 var scene = load("res://assets/vfx/megumin_explosion/source/1.fbx").instantiate()
 root.add_child(scene)
 var player = scene.find_child("AnimationPlayer",true,false)
 var animation = player.get_animation("Scene")
 print("LENGTH ",animation.length," TRACKS ",animation.get_track_count())
 for i in animation.get_track_count():
  print(animation.track_get_path(i)," TYPE ",animation.track_get_type(i))
 player.play("Scene")
 for time in [0.0,0.5,1.0,2.0,3.0,4.0,5.0]:
  player.seek(minf(time,animation.length),true)
  var bounds := AABB()
  for mesh in scene.find_children("*","MeshInstance3D",true,false):
   bounds = bounds.merge(mesh.global_transform * mesh.get_aabb())
  print("BOUNDS ",time," ",bounds)
 quit()
