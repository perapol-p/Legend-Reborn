extends StaticBody3D
func _ready() -> void:
	add_to_group("unstable_cover")
	var original := $Mesh.mesh as BoxMesh
	var width := original.size.x
	var depth := original.size.z
	var height := maxf(original.size.y, width * 0.9)
	var pyramid := CylinderMesh.new()
	pyramid.top_radius = 0.0
	pyramid.bottom_radius = width / sqrt(2.0)
	pyramid.height = height
	pyramid.radial_segments = 4
	pyramid.rings = 1
	pyramid.material = original.material
	$Mesh.mesh = pyramid
	$Mesh.rotation.y = PI / 4.0
	$Mesh.scale.z = depth / width
	position.y = height * 0.5
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([Vector3(-width/2,-height/2,-depth/2),Vector3(width/2,-height/2,-depth/2),Vector3(width/2,-height/2,depth/2),Vector3(-width/2,-height/2,depth/2),Vector3(0,height/2,0)])
	$Collision.shape = shape
	var slippery := PhysicsMaterial.new()
	slippery.friction = 0.0
	physics_material_override = slippery
