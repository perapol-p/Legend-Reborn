extends SceneTree
func _initialize(): call_deferred("preview")
func preview():
 var world := Node3D.new()
 root.add_child(world)
 var env := WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color.WHITE
 env.environment.ambient_light_energy = 0.6
 world.add_child(env)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-35,-30,0)
 world.add_child(light)
 var camera := Camera3D.new()
 world.add_child(camera)
 camera.position = Vector3(0,3,-9)
 camera.look_at(Vector3(0,2,0))
 for kind in ["golem","eye"]:
  var asset = load("res://assets/monsters/golem/golem.glb" if kind == "golem" else "res://assets/monsters/flying_eye/source/flying_eye_stand.fbx").instantiate()
  asset.scale = Vector3.ONE*(0.3 if kind == "golem" else 0.6)
  asset.rotation.y = PI
  asset.position = Vector3(0.28,-2.10,-0.24) if kind == "golem" else Vector3(0,0.65,0)
  world.add_child(asset)
  var anim = asset.find_child("AnimationPlayer",true,false)
  anim.play("Idle" if kind == "golem" else "fly")
  await create_timer(0.25).timeout
  for mesh in asset.find_children("*","MeshInstance3D",true,false):
   for i in mesh.mesh.get_surface_count():
    var mat = mesh.mesh.surface_get_material(i)
    print(kind," MATERIAL ",mat.resource_name," COLOR ",mat.albedo_color," TEXTURE ",mat.albedo_texture)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/"+kind+"_asset_preview.png")
  asset.queue_free()
  await process_frame
 world.queue_free()
 await process_frame
 quit()
