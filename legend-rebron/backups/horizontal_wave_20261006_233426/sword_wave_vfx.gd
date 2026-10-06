extends Node3D
## Layered tapered crescent; no renderer glow dependency.
const WAVE_SHADER = preload("res://shaders/sword_wave.gdshader")
var radius := 1.0
var age := 0.0
var materials: Array[ShaderMaterial] = []
func _ready() -> void:
	rotation.z = -0.30
	var mesh := _crescent_mesh()
	for i in 3:
		var crescent := MeshInstance3D.new()
		crescent.name = "Crescent" + str(i)
		crescent.mesh = mesh
		crescent.position.z = float(i) * 0.24
		crescent.scale = Vector3.ONE * (1.0 - float(i) * 0.06)
		crescent.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = WAVE_SHADER
		material.set_shader_parameter("tint", Color(0.20, 0.75, 1.0, 1.0 if i == 0 else 0.24 / float(i)))
		crescent.material_override = material
		materials.append(material)
		add_child(crescent)
	var particles := CPUParticles3D.new()
	particles.name = "EnergySparks"
	particles.amount = 20
	particles.lifetime = 0.22
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(radius * 0.72, radius * 0.16, 0.04)
	particles.direction = Vector3(0, 0, 1)
	particles.spread = 22.0
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 2.0
	particles.gravity = Vector3.ZERO
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.7, 0.95, 1.0, 0.8))
	gradient.set_color(1, Color(0.2, 0.65, 1.0, 0.0))
	particles.color_ramp = gradient
	var spark := BoxMesh.new()
	spark.size = Vector3(0.025, 0.025, 0.15)
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.vertex_color_use_as_albedo = true
	spark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark.material = spark_material
	particles.mesh = spark
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
func _process(delta: float) -> void:
	age += delta
	var projectile = get_parent()
	var opacity := minf(age / 0.045, 1.0) * minf(projectile.remaining / 0.20, 1.0)
	for material in materials:
		material.set_shader_parameter("opacity", opacity)
func _crescent_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	const SEGMENTS := 40
	for i in range(SEGMENTS + 1):
		var t := float(i) / SEGMENTS
		var angle := lerpf(-1.38, 1.38, t)
		var width := radius * 0.30 * pow(sin(t * PI), 0.8)
		for edge in 2:
			var r := radius - width if edge == 0 else radius
			vertices.append(Vector3(sin(angle) * r, cos(angle) * r - radius * 0.48, 0.0))
			uvs.append(Vector2(t, float(edge)))
		if i < SEGMENTS:
			var start := i * 2
			indices.append_array(PackedInt32Array([start, start + 1, start + 2, start + 1, start + 3, start + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
