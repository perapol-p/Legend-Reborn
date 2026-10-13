extends SceneTree
func _initialize(): call_deferred("build")
func build():
 var library := AnimationLibrary.new()
 for spec in [
  ["Rig_Medium_MovementBasic.glb",["Walking_B"]],
  ["Rig_Medium_General.glb",["Death_A"]],
  ["Rig_Medium_CombatRanged.glb",["Ranged_2H_Aiming","Ranged_2H_Shoot"]]]:
  var model = load("res://assets/monsters/skeleton_archer/"+spec[0]).instantiate()
  var player = model.find_child("AnimationPlayer",true,false)
  for name in spec[1]:
   var animation = player.get_animation(name).duplicate()
   if name == "Walking_B": animation.loop_mode = Animation.LOOP_LINEAR
   library.add_animation(name,animation)
  model.free()
 assert(ResourceSaver.save(library,"res://assets/monsters/skeleton_archer/archer_animations.res",ResourceSaver.FLAG_COMPRESS)==OK)
 print("Packed archer animation library: ",library.get_animation_list())
 for path in ["res://assets/monsters/flying_eye/source/flying_eye_stand.fbx","res://assets/monsters/zombie/zombie.fbx"]:
  var model = load(path).instantiate()
  var count := 0
  for mesh in model.find_children("*","MeshInstance3D",true,false):
   for i in mesh.mesh.get_surface_count(): count += mesh.mesh.surface_get_array_len(i)
  print(path," vertices: ",count)
  model.free()
 quit()
