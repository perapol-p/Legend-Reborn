extends "res://scripts/arena_layout.gd"
@export var biome := "grassland"
const CELL := 4.0
const SIZE := 160.0
var generated: Node3D
var materials: Dictionary = {}
var batches: Dictionary = {}
var transforms: Dictionary = {}
var obstacle_points: Array[Vector3] = []
var scenery_rng := RandomNumberGenerator.new()

func _ready() -> void:
 scenery_rng.seed = 71023 if biome == "grassland" else 94017
 # Normal stages have natural terrain; Practice retains the original grid arena.
 for name in ["Floor","Terrain","Cover"]:
  var old = get_node_or_null(name)
  if old != null: old.free()
 for mesh in $Boundaries.find_children("*","MeshInstance3D",true,false): mesh.hide()
 for wall in $Boundaries.get_children():
  wall.position.y = 8.0
  var collision = wall.get_node("Collision")
  collision.shape = collision.shape.duplicate()
  collision.shape.size.y = 24.0
 generated = Node3D.new()
 generated.name = "BiomeLandscape"
 add_child(generated)
 _configure_light()
 _build_ground()
 _build_cliffs()
 _build_landmarks()
 _scatter_props()
 _finish_batches()

func _material(key: String, color: Color) -> StandardMaterial3D:
 if materials.has(key): return materials[key]
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 1.0
 material.metallic_specular = 0.0
 materials[key] = material
 return material

func _configure_light() -> void:
 var forest := biome == "grassland"
 var environment = $WorldEnvironment.environment.duplicate()
 $WorldEnvironment.environment = environment
 var sky_material := ProceduralSkyMaterial.new()
 sky_material.sky_top_color = Color("668eaa") if forest else Color("7298b3")
 sky_material.sky_horizon_color = Color("b4c8cc") if forest else Color("d6c9a8")
 sky_material.ground_bottom_color = Color("64754c") if forest else Color("a78e62")
 sky_material.ground_horizon_color = sky_material.sky_horizon_color
 var sky := Sky.new()
 sky.sky_material = sky_material
 environment.background_mode = Environment.BG_SKY
 environment.sky = sky
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("c6d4bd") if forest else Color("e8dcc0")
 environment.ambient_light_energy = 0.45
 environment.fog_light_color = sky_material.sky_horizon_color
 environment.fog_density = 0.0016
 $Sun.rotation_degrees = Vector3(-48,-28,0)
 $Sun.light_color = Color("fff5df")
 $Sun.light_energy = 0.65
 $Sun.shadow_enabled = true
 $Sun.directional_shadow_max_distance = 70.0

func _height(x: float, z: float) -> float:
 var clearing := smoothstep(18.0,32.0,Vector2(x,z).length())
 var height: float
 if biome == "grassland":
  height = 4.5 * exp(-Vector2(x+34,z+22).length_squared()/500.0)
  height += 3.6 * exp(-Vector2(x-39,z-25).length_squared()/600.0)
  height += 2.8 * exp(-Vector2(x-28,z+46).length_squared()/440.0)
  height += (sin(x*0.055+0.8)*cos(z*0.047)+1.0)*0.45
 else:
  height = 3.6 * exp(-Vector2(x+36,z+29).length_squared()/680.0)
  height += 4.0 * exp(-Vector2(x-42,z-23).length_squared()/720.0)
  height += 2.5 * exp(-Vector2(x-14,z+53).length_squared()/520.0)
  height += (sin(x*0.05+z*0.023)+1.0)*0.35
 return height * clearing

func ground_height(x: float, z: float) -> float:
 # Match the actual triangle surface, rather than approximating the hills.
 var ax := clampf(floorf((x+80.0)/CELL)*CELL-80.0,-80.0,76.0)
 var az := clampf(floorf((z+80.0)/CELL)*CELL-80.0,-80.0,76.0)
 var u := clampf((x-ax)/CELL,0.0,1.0)
 var v := clampf((z-az)/CELL,0.0,1.0)
 var a := _height(ax,az)
 var b := _height(ax+CELL,az)
 var c := _height(ax,az+CELL)
 var d := _height(ax+CELL,az+CELL)
 return a+(b-a)*u+(c-a)*v if u+v <= 1.0 else d+(c-d)*(1.0-u)+(b-d)*(1.0-v)

func _ground_color(x: float, z: float) -> Color:
 var path_distance := minf(absf(x-7.0*sin(z*0.055)),absf(z+18.0-6.0*sin(x*0.055)))
 var blend := smoothstep(2.5,6.0,path_distance)
 if biome == "grassland":
  var grass := Color("748e52").lerp(Color("647f49"),(sin(x*0.075+0.7)*cos(z*0.07)+1.0)*0.5)
  return Color("a39b76").lerp(grass,blend)
 return Color("c2aa77").lerp(Color("d0b983"),(sin(x*0.055+z*0.035)+1.0)*0.5).lerp(Color("bda273"),(1.0-blend)*0.18)

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color, terrain_colors := false) -> void:
 var normal := (b-a).cross(c-a).normalized()
 if normal.y < 0.0:
  var swap := b
  b = c
  c = swap
  normal = -normal
 for vertex in [a,c,b]:
  surface.set_normal(normal)
  surface.set_color((_ground_color(vertex.x,vertex.z) if terrain_colors else color).srgb_to_linear())
  surface.add_vertex(vertex)

func _mesh_body(name: String, mesh: ArrayMesh, material: Material, collides := true) -> StaticBody3D:
 var body := StaticBody3D.new()
 body.name = name
 generated.add_child(body)
 var visual := MeshInstance3D.new()
 visual.mesh = mesh
 visual.material_override = material
 body.add_child(visual)
 if collides:
  var collision := CollisionShape3D.new()
  var shape := mesh.create_trimesh_shape()
  shape.backface_collision = true
  collision.shape = shape
  body.add_child(collision)
 return body

func _build_ground() -> void:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for zi in 40:
  for xi in 40:
   var x := -80.0+xi*CELL
   var z := -80.0+zi*CELL
   var a := Vector3(x,_height(x,z),z)
   var b := Vector3(x+CELL,_height(x+CELL,z),z)
   var c := Vector3(x,_height(x,z+CELL),z+CELL)
   var d := Vector3(x+CELL,_height(x+CELL,z+CELL),z+CELL)
   var color := _ground_color(x+CELL*0.5,z+CELL*0.5)
   _triangle(surface,a,b,c,color,true)
   _triangle(surface,b,d,c,color,true)
 var material := _material("ground",Color.WHITE)
 material.vertex_color_use_as_albedo = true
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 _mesh_body("RollingTerrain",surface.commit(),material)

func _build_cliffs() -> void:
 var points: Array[Vector2] = []
 for side in 4:
  for i in 20:
   var t := -78.0+156.0*float(i)/20.0
   match side:
    0: points.append(Vector2(t,-78))
    1: points.append(Vector2(78,t))
    2: points.append(Vector2(-t,78))
    3: points.append(Vector2(-78,-t))
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var forest := biome == "grassland"
 for i in points.size():
  var p := points[i]
  var q := points[(i+1)%points.size()]
  var a := Vector3(p.x,ground_height(p.x,p.y)-0.1,p.y)
  var b := Vector3(q.x,ground_height(q.x,q.y)-0.1,q.y)
  var c := Vector3(q.x*1.13,12.0+sin(float(i+1)*1.3)*2.0,q.y*1.13)
  var d := Vector3(p.x*1.13,12.0+sin(float(i)*1.3)*2.0,p.y*1.13)
  var color := Color("7f866f") if forest else Color("a1865d")
  color = color.darkened(0.06*(float(i%3)))
  _triangle(surface,a,b,c,color)
  _triangle(surface,a,c,d,color)
  var outer_c := c+Vector3(c.x*0.08,-1.0,c.z*0.08)
  var outer_d := d+Vector3(d.x*0.08,-1.0,d.z*0.08)
  _triangle(surface,d,outer_d,outer_c,color.lightened(0.07))
  _triangle(surface,d,outer_c,c,color.lightened(0.07))
 var material := _material("cliffs",Color.WHITE)
 material.vertex_color_use_as_albedo = true
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 _mesh_body("PerimeterCliffs",surface.commit(),material)

func _add_batch(key: String, mesh: Mesh, material: Material, position: Vector3, scale_value: Vector3, rotation_y := 0.0) -> void:
 if not batches.has(key):
  mesh.material = material
  batches[key] = mesh
  transforms[key] = []
 var basis := Basis(Vector3.UP,rotation_y).scaled(scale_value)
 transforms[key].append(Transform3D(basis,position))

func _cylinder(top: float, bottom: float, height: float, segments := 7) -> CylinderMesh:
 var mesh := CylinderMesh.new()
 mesh.top_radius = top
 mesh.bottom_radius = bottom
 mesh.height = height
 mesh.radial_segments = segments
 return mesh

func _obstacle(point: Vector3, radius: float, height: float, name: String) -> void:
 var body := StaticBody3D.new()
 body.name = name
 body.position = point+Vector3.UP*height*0.5
 generated.add_child(body)
 var collision := CollisionShape3D.new()
 var shape := CylinderShape3D.new()
 shape.radius = radius
 shape.height = height
 collision.shape = shape
 body.add_child(collision)
 obstacle_points.append(point)

func _tree(point: Vector3, size_value: float, pine: bool) -> void:
 point.y = ground_height(point.x,point.z)
 var bark := _material("bark",Color("6a5740"))
 _add_batch("trunks",_cylinder(0.3,0.45,4.0),bark,point+Vector3.UP*2.0*size_value,Vector3.ONE*size_value)
 _obstacle(point,0.45*size_value,4.0*size_value,"TreeTrunk")
 var leaf := _material("pine" if pine else "leaf",Color("4c6844") if pine else Color("5c7948"))
 if pine:
  for tier in 3:
   _add_batch("pine"+str(tier),_cylinder(0.0,2.2-float(tier)*0.45,2.8),leaf,point+Vector3.UP*(3.3+float(tier)*1.5)*size_value,Vector3.ONE*size_value)
 else:
  var crown := SphereMesh.new()
  crown.radius = 2.5
  crown.height = 4.2
  crown.radial_segments = 7
  crown.rings = 3
  _add_batch("broadleaf",crown,leaf,point+Vector3.UP*5.0*size_value,Vector3(1.1,1.0,0.95)*size_value)

func _cactus(point: Vector3, size_value: float) -> void:
 point.y = ground_height(point.x,point.z)
 var green := _material("cactus",Color("63805a"))
 _add_batch("cactus_main",_cylinder(0.24,0.32,2.6,6),green,point+Vector3.UP*1.3*size_value,Vector3.ONE*size_value)
 _obstacle(point,0.34*size_value,2.6*size_value,"Cactus")
 for side in [-1.0,1.0]:
  _add_batch("cactus_arms",_cylinder(0.16,0.20,1.4,6),green,point+Vector3(side*0.6,1.75,0)*size_value,Vector3.ONE*size_value)
  var box := BoxMesh.new()
  box.size = Vector3(0.6,0.28,0.28)
  _add_batch("cactus_branches",box,green,point+Vector3(side*0.35,1.15,0)*size_value,Vector3.ONE*size_value)

func _rock(point: Vector3, size_value: float) -> void:
 point.y = ground_height(point.x,point.z)
 var mesh := SphereMesh.new()
 mesh.radius = 1.0
 mesh.height = 1.5
 mesh.radial_segments = 5
 mesh.rings = 2
 var material := _material("rocks",Color("7e846c") if biome == "grassland" else Color("a68b61"))
 _add_batch("boulders",mesh,material,point+Vector3.UP*0.55*size_value,Vector3(1.1,0.85,0.8)*size_value,scenery_rng.randf_range(0,TAU))
 _obstacle(point,0.85*size_value,1.15*size_value,"Boulder")

func _stone_box(name: String, point: Vector3, dimensions: Vector3, material: Material) -> void:
 var body := StaticBody3D.new()
 body.name = name
 body.position = point
 generated.add_child(body)
 var visual := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = dimensions
 mesh.material = material
 visual.mesh = mesh
 body.add_child(visual)
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = dimensions
 collision.shape = shape
 body.add_child(collision)
 obstacle_points.append(point-Vector3.UP*dimensions.y*0.5)

func _build_landmarks() -> void:
 if biome == "grassland":
  var stone := _material("ancient_stone",Color("9b9d7e"))
  var center := Vector3(-35,0,-29)
  center.y = ground_height(center.x,center.z)
  for side in [-1.0,1.0]:
   _stone_box("ForestArchPillar",center+Vector3(side*4.0,3.0,0),Vector3(1.6,6.0,1.8),stone)
  _stone_box("ForestArchLintel",center+Vector3(0,6.1,0),Vector3(10.2,1.4,2.0),stone)
  for point in [Vector3(38,0,32),Vector3(46,0,27),Vector3(38,0,22)]:
   var h := ground_height(point.x,point.z)
   _stone_box("OldStandingStone",Vector3(point.x,h+2.0,point.z),Vector3(1.2,4.0,1.0),stone)
  for i in 5: _tree(Vector3(-52+float(i)*4,0,36),1.2+i*0.06,i%2==0)
 else:
  var stone := _material("sandstone",Color("b39261"))
  var center := Vector3(38,ground_height(38,-29),-29)
  for side in [-1.0,1.0]:
   _stone_box("DesertGatePillar",center+Vector3(side*4.2,3.3,0),Vector3(2.0,6.6,2.3),stone)
  _stone_box("DesertGateLintel",center+Vector3(0,6.8,0),Vector3(11.0,1.5,2.8),stone)
  for i in 3:
   var point := Vector3(-38+float(i)*5,0,-38)
   point.y = ground_height(point.x,point.z)
   _stone_box("SandstoneObelisk",point+Vector3.UP*(3.0+float(i)),Vector3(1.3,6.0+float(i)*2.0,1.3),stone)
  _oasis()

func _oasis() -> void:
 var point := Vector3(-40,ground_height(-40,31)+0.035,31)
 var water := _material("oasis_water",Color("679998"))
 var lake := MeshInstance3D.new()
 lake.name = "Oasis"
 lake.mesh = _cylinder(5.8,5.8,0.04,16)
 lake.mesh.material = water
 lake.position = point
 generated.add_child(lake)
 # Decorative water has no pit or surface animation to distract from combat.
 for i in 3:
  var angle := float(i)*TAU/3.0
  var base := point+Vector3(cos(angle)*7.5,0,sin(angle)*7.5)
  base.y = ground_height(base.x,base.z)
  _add_batch("palm_trunks",_cylinder(0.2,0.34,5.0,6),_material("palm_bark",Color("827053")),base+Vector3.UP*2.5,Vector3.ONE)
  _obstacle(base,0.35,5.0,"PalmTree")
  for leaf_index in 5:
   var leaf := PrismMesh.new()
   leaf.size = Vector3(1.1,0.35,4.6)
   _add_batch("palm_leaves",leaf,_material("palm_leaf",Color("748658")),base+Vector3.UP*5.0,Vector3.ONE,float(leaf_index)*TAU/5.0)

func _scatter_props() -> void:
 var forest := biome == "grassland"
 for i in (75 if forest else 40):
  var point := Vector3(scenery_rng.randf_range(-70,70),0,scenery_rng.randf_range(-70,70))
  if Vector2(point.x,point.z).length() < 25.0: continue
  if absf(point.x-7.0*sin(point.z*0.055)) < 8.0: continue
  if absf(point.z+18.0-6.0*sin(point.x*0.055)) < 8.0: continue
  if point.distance_to(Vector3(-40,0,31)) < 10.0 and not forest: continue
  var blocked := false
  for other in obstacle_points:
   if Vector2(point.x-other.x,point.z-other.z).length() < 4.5:
    blocked = true
    break
  if blocked: continue
  var size_value := scenery_rng.randf_range(0.75,1.3)
  if forest: _tree(point,size_value,i%3==0)
  else: _cactus(point,size_value)
 for i in 15:
  var point := Vector3(scenery_rng.randf_range(-68,68),0,scenery_rng.randf_range(-68,68))
  if Vector2(point.x,point.z).length() > 28.0:
   _rock(point,scenery_rng.randf_range(0.7,1.4))

func _finish_batches() -> void:
 for key in batches:
  var instance := MultiMeshInstance3D.new()
  instance.name = str(key).to_pascal_case()
  var multi := MultiMesh.new()
  multi.transform_format = MultiMesh.TRANSFORM_3D
  multi.mesh = batches[key]
  multi.instance_count = transforms[key].size()
  for i in multi.instance_count: multi.set_instance_transform(i,transforms[key][i])
  instance.multimesh = multi
  generated.add_child(instance)

func movement_target(_actor: Node3D, target: Vector3) -> Vector3:
 # Every hill is reachable directly; there are no vertical platform faces.
 return target

func ensure_actor_clearance(actor: Node3D) -> void:
 var point := to_local(actor.global_position)
 var height := ground_height(point.x,point.z)
 if point.y < height+0.06:
  point.y = height+0.06
  actor.global_position = to_global(point)

func is_spawn_point_inside(point: Vector3) -> bool:
 var local := to_local(point)
 return absf(local.x) <= 73.0 and absf(local.z) <= 73.0
