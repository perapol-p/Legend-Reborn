extends "res://scripts/arena_layout.gd"
@export var biome := "grassland"
func _ready() -> void:
	var grassy := biome == "grassland"
	var ground := _material(Color("344938") if grassy else Color("997d50"))
	var stone := _material(Color("50594c") if grassy else Color("816849"))
	for mesh in find_children("*","MeshInstance3D",true,false):
		if mesh.get_parent().name == "Floor" or mesh.get_parent().get_parent().name == "Terrain":
			mesh.mesh = mesh.mesh.duplicate()
			mesh.mesh.material = ground
		elif mesh.get_parent().get_parent().name in ["Cover","Boundaries"]:
			mesh.mesh = mesh.mesh.duplicate()
			mesh.mesh.material = stone
	$Sun.light_energy = 0.7
	$Sun.shadow_enabled = false
	var landmarks := Node3D.new()
	landmarks.name = "Trees" if grassy else "StoneRuins"
	add_child(landmarks)
	for point in [Vector3(-55,0,-48),Vector3(54,0,-50),Vector3(-52,0,46),Vector3(55,0,44),Vector3(-58,0,8),Vector3(55,0,0)]:
		if grassy:
			_add_tree(landmarks,point)
		else:
			_add_ruin(landmarks,point,stone)
func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic_specular = 0.0
	return material
func _add_tree(parent: Node3D, point: Vector3) -> void:
	var tree := StaticBody3D.new()
	tree.position = point
	parent.add_child(tree)
	var trunk := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.45
	cylinder.height = 3.0
	cylinder.radial_segments = 8
	cylinder.material = _material(Color("5d4832"))
	trunk.mesh = cylinder
	trunk.position.y = 1.5
	tree.add_child(trunk)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 3.0
	collision.shape = capsule
	collision.position.y = 1.5
	tree.add_child(collision)
	var foliage := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.0
	sphere.height = 3.0
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere.material = _material(Color("3d6747"))
	foliage.mesh = sphere
	foliage.position.y = 3.8
	tree.add_child(foliage)
func _add_ruin(parent: Node3D, point: Vector3, material: Material) -> void:
	var ruin := StaticBody3D.new()
	ruin.set_script(preload("res://scripts/pyramid_cover.gd"))
	ruin.position = point
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = Vector3(5,3,4)
	box.material = material
	mesh.mesh = box
	ruin.add_child(mesh)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = BoxShape3D.new()
	ruin.add_child(collision)
	parent.add_child(ruin)


