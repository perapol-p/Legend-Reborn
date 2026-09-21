extends Node3D
## A small, walkable refuge. Only the dungeon gate accepts interaction.
const PLAYER = preload("res://player/player_charbody3d.tscn")
const LOBBY_UI = preload("res://home/lobby_hud.gd")
var player: CharacterBody3D
var gate: Node3D
var portal_material: ShaderMaterial
var hud: CanvasLayer
var stone: StandardMaterial3D
var dark_stone: StandardMaterial3D
var wood: StandardMaterial3D
var brass: StandardMaterial3D
var cloth: StandardMaterial3D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 1407
	stone = material(Color("aaa69d"))
	stone.albedo_texture = preload("res://demo_level/gridmap/gridmap_materials/TinyBrick01_albedo.png")
	stone.uv1_triplanar = true
	dark_stone = material(Color("70767c"))
	dark_stone.albedo_texture = preload("res://demo_level/gridmap/gridmap_materials/TinyBrick02_albedo.png")
	dark_stone.uv1_triplanar = true
	wood = material(Color("80634a"))
	wood.albedo_texture = preload("res://demo_level/gridmap/gridmap_materials/TinyWood03_albedo.png")
	wood.uv1_triplanar = true
	brass = material(Color("a68a51"), 0.55)
	cloth = material(Color("46555b"))
	build_environment()
	build_courtyard()
	build_gate()
	build_quest_board()
	build_merchant()
	player = PLAYER.instantiate()
	player.name = "Player"
	player.position = Vector3(0, 0.15, 5.0)
	player.rotation.y = PI
	var camera = player.get_node("FollowCam")
	camera.position = Vector3(0, 2.8, 5)
	camera.rotation = Vector3(-0.16, 0, 0)
	camera.spring_length = 4.6
	add_child(player)
	hud = LOBBY_UI.new()
	hud.lobby = self
	add_child(hud)
	var music := AudioStreamPlayer.new()
	music.name = "RefugeMusic"
	music.stream = preload("res://audio/bone_in_the_walls__level_loop_session.ogg")
	music.bus = &"Music"
	music.volume_db = -13
	add_child(music)
	music.play()

func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.88
	result.metallic = metallic
	return result

func box(parent: Node3D, title: String, position_: Vector3, size_: Vector3, surface: Material, collision: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var shape := BoxMesh.new()
	shape.size = size_
	mesh.mesh = shape
	mesh.material_override = surface
	mesh.position = position_
	parent.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size_
		collider.shape = bounds
		body.add_child(collider)
		mesh.add_child(body)
	return mesh

func cylinder(parent: Node3D, position_: Vector3, radius: float, height: float, surface: Material, top_radius: float = -1) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top_radius < 0 else top_radius
	shape.height = height
	shape.radial_segments = 16
	mesh.mesh = shape
	mesh.material_override = surface
	mesh.position = position_
	parent.add_child(mesh)
	return mesh

func text3d(parent: Node3D, words: String, position_: Vector3, size_: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = position_
	label.font_size = size_
	label.pixel_size = 0.007
	label.modulate = color
	label.outline_modulate = Color("151719")
	label.outline_size = 9
	label.no_depth_test = false
	parent.add_child(label)
	return label

func build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("344c62")
	sky_material.sky_horizon_color = Color("a29b85")
	sky_material.ground_bottom_color = Color("242a2e")
	sky_material.ground_horizon_color = Color("8e9287")
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a7b6c5")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_color = Color("ffe1af")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 145, 0)
	fill.light_color = Color("88b5db")
	fill.light_energy = 0.4
	add_child(fill)

func build_courtyard() -> void:
	box(self, "Foundation", Vector3(0, -0.3, -1), Vector3(28, 0.6, 25), dark_stone, true)
	for x in range(-7, 7):
		for z in range(-6, 6):
			var tint: float = rng.randf_range(0.82, 1.13)
			var tile := material(Color("a29f8e") * tint)
			tile.albedo_texture = preload("res://demo_level/gridmap/gridmap_materials/TinyCobble01_albedo.png")
			tile.uv1_triplanar = true
			box(self, "Paving", Vector3(x * 1.94 + 0.97, 0.02, z * 1.94), Vector3(1.90, 0.04, 1.90), tile)
	box(self, "BackWallLeft", Vector3(-8.1, 2.7, -10.3), Vector3(11.4, 5.4, 0.8), dark_stone, true)
	box(self, "BackWallRight", Vector3(8.1, 2.7, -10.3), Vector3(11.4, 5.4, 0.8), dark_stone, true)
	box(self, "GateBackWall", Vector3(0, 3.5, -10.5), Vector3(5, 7, 0.8), dark_stone, true)
	for x in [-13.6, 13.6]:
		box(self, "SideWall", Vector3(x, 1.35, 0), Vector3(0.65, 2.7, 21), dark_stone, true)
		for z in range(-9, 11, 4):
			box(self, "WallPier", Vector3(x, 1.8, z), Vector3(1.1, 3.6, 1.1), stone, true)
			box(self, "PierCap", Vector3(x, 3.65, z), Vector3(1.35, 0.25, 1.35), stone)
	box(self, "FrontWall", Vector3(0, 0.8, 11), Vector3(28, 1.6, 0.7), dark_stone, true)
	for x in range(-12, 13, 3):
		box(self, "Battlement", Vector3(x, 5.7, -10.3), Vector3(1.15, 0.65, 1.0), stone)
	for x in [-11.0, 11.0]:
		box(self, "Tower", Vector3(x, 4.2, -12), Vector3(3.1, 8.4, 3.1), dark_stone)
		for corner in [-1.0, 1.0]:
			box(self, "TowerCrown", Vector3(x + corner, 8.7, -11), Vector3(0.7, 1.0, 0.7), stone)
	for x in [-4.7, 4.7]:
		box(self, "BannerPole", Vector3(x, 3.9, -9.7), Vector3(0.1, 5.2, 0.1), brass)
		box(self, "Banner", Vector3(x + 0.5, 4.6, -9.65), Vector3(1.0, 2.5, 0.08), cloth)
		text3d(self, "R", Vector3(x + 0.5, 4.6, -9.56), 96, Color("e5cb84"))
	for x in [-3.4, 3.4]:
		brazier(Vector3(x, 0, -5.6))
	# Low benches and greenery make the hub read as a resting place.
	for x in [-9.3, 9.3]:
		box(self, "Bench", Vector3(x, 0.65, 3), Vector3(2.8, 0.22, 0.7), wood, true)
		for offset in [-0.95, 0.95]:
			box(self, "BenchLeg", Vector3(x + offset, 0.3, 3), Vector3(0.2, 0.6, 0.5), dark_stone)
	var moss := material(Color("414d32"))
	for point in [Vector3(-11, 0.22, -7), Vector3(11, 0.22, -7), Vector3(-11, 0.22, 6), Vector3(11, 0.22, 6)]:
		cylinder(self, point, 1.0, 0.4, dark_stone)
		cylinder(self, point + Vector3.UP * 0.4, 0.85, 0.6, moss, 0.3)

func brazier(position_: Vector3) -> void:
	cylinder(self, position_ + Vector3.UP * 0.6, 0.18, 1.2, dark_stone)
	cylinder(self, position_ + Vector3.UP * 1.25, 0.4, 0.3, brass, 0.55)
	var fire := material(Color("ffb94d"))
	fire.emission_enabled = true
	fire.emission = Color("ff942b")
	fire.emission_energy_multiplier = 2.2
	cylinder(self, position_ + Vector3.UP * 1.6, 0.26, 0.7, fire, 0.025)
	var light := OmniLight3D.new()
	light.position = position_ + Vector3.UP * 1.8
	light.light_color = Color("ffb766")
	light.light_energy = 2.0
	light.omni_range = 6.0
	add_child(light)

func build_gate() -> void:
	gate = Node3D.new()
	gate.name = "DungeonGate"
	gate.position = Vector3(0, 0, -8.4)
	add_child(gate)
	box(gate, "Threshold", Vector3(0, 0.09, 0.1), Vector3(5.1, 0.18, 1.8), stone, true)
	for x in [-2.2, 2.2]:
		for y in range(6):
			box(gate, "ArchPier", Vector3(x, 0.3 + y * 0.55, 0), Vector3(0.85, 0.51, 1.1), stone, true)
	for index in range(13):
		var angle: float = float(index) / 12.0 * PI
		var block := box(gate, "ArchStone", Vector3(cos(angle) * 2.2, 3.0 + sin(angle) * 2.2, 0), Vector3(0.65, 0.85, 1.1), stone)
		block.rotation.z = angle - PI * 0.5
	var portal := MeshInstance3D.new()
	portal.name = "Portal"
	var quad := QuadMesh.new()
	quad.size = Vector2(3.8, 4.8)
	portal.mesh = quad
	portal.position = Vector3(0, 2.5, 0.08)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment() {
    if (UV.y < 0.34 && length(vec2((UV.x-0.5)*2.0, (UV.y-0.34)/0.34)) > 1.0) discard;
    vec2 p = (UV-vec2(0.5))*vec2(1.0,1.3);
    float r = length(p);
    float a = atan(p.y,p.x);
    float waves = sin(r*32.0-a*3.0-TIME*1.5)*0.5+0.5;
    float veins = pow(waves, 10.0);
    float edge = pow(abs(UV.x-0.5)*2.0, 9.0);
    vec3 base = mix(vec3(0.015,0.035,0.06), vec3(0.04,0.23,0.29), waves*0.45);
    ALBEDO = base + vec3(0.2,0.68,0.72)*veins*0.35 + vec3(0.6,0.8,0.65)*edge;
    EMISSION = vec3(0.06,0.3,0.35)*veins;
}
"""
	portal_material = ShaderMaterial.new()
	portal_material.shader = shader
	portal.material_override = portal_material
	gate.add_child(portal)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 2.4, 1.2)
	glow.light_color = Color("5fe0e1")
	glow.light_energy = 3.3
	glow.omni_range = 7.0
	gate.add_child(glow)
	text3d(gate, "DUNGEON", Vector3(0, 6.0, 0.65), 64, Color("e8d5a1"))
	text3d(gate, "CASTLE OUTSKIRTS", Vector3(0, 5.55, 0.65), 27, Color("92c6c5"))

func build_quest_board() -> void:
	var board := Node3D.new()
	board.name = "QuestBoard"
	board.position = Vector3(-7.3, 0, -4.5)
	board.rotation.y = 0.22
	add_child(board)
	box(board, "Board", Vector3(0, 1.85, 0), Vector3(3.4, 2.0, 0.24), wood, true)
	for x in [-1.7, 1.7]:
		box(board, "Post", Vector3(x, 1.5, 0), Vector3(0.2, 3.0, 0.3), wood, true)
	box(board, "Roof", Vector3(0, 3.1, 0), Vector3(3.95, 0.2, 0.8), dark_stone)
	var parchment := material(Color("cbb995"))
	for index in range(5):
		var x: float = -1.2 + (index % 3) * 0.85
		var y: float = 2.25 - int(index / 3.0) * 0.8
		var page := box(board, "Notice", Vector3(x, y, 0.14), Vector3(0.59, 0.69, 0.035), parchment)
		page.rotation.z = rng.randf_range(-0.12, 0.12)
		for line in range(3):
			box(board, "Ink", Vector3(x, y + 0.15 - line * 0.13, 0.17), Vector3(0.35, 0.025, 0.01), wood)
	text3d(board, "QUEST BOARD", Vector3(0, 3.7, 0.25), 50, Color("d9c497"))
	text3d(board, "COMING SOON", Vector3(0, 3.3, 0.25), 25, Color("aaa89a"))
	board.set_meta("available", false)

func build_merchant() -> void:
	var stall := Node3D.new()
	stall.name = "Merchant"
	stall.position = Vector3(7.4, 0, -4.5)
	stall.rotation.y = -0.2
	add_child(stall)
	box(stall, "Counter", Vector3(0, 0.95, 0.4), Vector3(3.8, 1.6, 1.0), wood, true)
	box(stall, "CounterTop", Vector3(0, 1.8, 0.4), Vector3(4.1, 0.16, 1.2), brass)
	for x in [-2.0, 2.0]:
		box(stall, "CanopyPost", Vector3(x, 1.7, 0), Vector3(0.16, 3.4, 0.16), wood, true)
	box(stall, "Canopy", Vector3(0, 3.4, 0), Vector3(4.6, 0.14, 2.2), cloth)
	for x in [-1.6, -0.8, 0.0, 0.8, 1.6]:
		box(stall, "CanopyTrim", Vector3(x, 3.14, 1.0), Vector3(0.63, 0.5, 0.08), cloth)
	for index in range(4):
		var jar := material([Color("8a3838"), Color("5e7d73"), Color("d4ab64"), Color("68708d")][index])
		cylinder(stall, Vector3(-1.3 + index * 0.64, 2.06, 0.4), 0.16, 0.36, jar, 0.1)
		cylinder(stall, Vector3(-1.3 + index * 0.64, 2.29, 0.4), 0.075, 0.11, brass)
	# A stationary hooded merchant silhouette; no shop logic or interaction area.
	var robe := material(Color("574b40"))
	cylinder(stall, Vector3(0.45, 1.0, -0.65), 0.4, 1.6, robe, 0.26)
	var hood := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	hood.mesh = sphere
	hood.position = Vector3(0.45, 2.0, -0.65)
	hood.material_override = robe
	stall.add_child(hood)
	box(stall, "FaceShadow", Vector3(0.45, 2.0, -0.39), Vector3(0.27, 0.27, 0.05), dark_stone)
	box(stall, "StockCrate", Vector3(2.7, 0.45, 0.1), Vector3(0.9, 0.9, 0.9), wood, true)
	cylinder(stall, Vector3(-2.8, 0.6, 0.1), 0.5, 1.2, wood)
	text3d(stall, "MERCHANT", Vector3(0, 4.05, 0.5), 50, Color("d9c497"))
	text3d(stall, "COMING SOON", Vector3(0, 3.67, 0.5), 25, Color("aaa89a"))
	stall.set_meta("available", false)

func near_gate() -> bool:
	if not is_instance_valid(player):
		return false
	var delta: Vector3 = player.global_position - gate.global_position
	return Vector2(delta.x, delta.z).length() < 3.2 and absf(delta.y) < 2.5

func try_enter_dungeon() -> bool:
	if not near_gate() or player.busy or player.dodging or player.is_dead:
		return false
	return get_node("/root/GameSession").enter_dungeon()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and near_gate():
		try_enter_dungeon()
		get_viewport().set_input_as_handled()
