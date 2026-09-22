extends Node3D
const Layout = preload("res://dungeon/layout_generator.gd")
const PLAYER = preload("res://player/player_charbody3d.tscn")
const ENEMY = preload("res://enemy/enemy_base_root_motion.tscn")
const CHEST = preload("res://interactable objects/chest/chest.tscn")
const CELL := 2.0
var layout = Layout.new()
var generation_seed: int
var player: CharacterBody3D
var exit_position: Vector3
var prompt: Label
var navigation_region: NavigationRegion3D

func _ready() -> void:
	var session = get_node("/root/GameSession")
	if session.dungeon_seed == 0:
		session.dungeon_seed = randi_range(1, 2147483646)
	generation_seed = session.dungeon_seed
	layout.generate(generation_seed)
	build_environment()
	build_geometry()
	build_navigation()
	var spawn := cell_position(layout.rooms[0].get_center())
	var farthest := 0.0
	exit_position = spawn
	for i in range(1, layout.rooms.size()):
		var center := cell_position(layout.rooms[i].get_center())
		if center.distance_squared_to(spawn) > farthest:
			farthest = center.distance_squared_to(spawn)
			exit_position = center
		var enemy = ENEMY.instantiate()
		enemy.name = "Guardian_%d" % i
		enemy.position = center + Vector3(2, 0.15, 0)
		add_child(enemy)
		if i % 2 == 0:
			var chest = CHEST.instantiate()
			chest.name = "Chest_%d" % i
			chest.position = center + Vector3(-2, 0, 2)
			add_child(chest)
		var lamp := OmniLight3D.new()
		lamp.position = center + Vector3(0, 3.5, 0)
		lamp.light_color = Color("ffc37c")
		lamp.light_energy = 1.8
		lamp.omni_range = 14.0
		add_child(lamp)
	build_exit()
	player = PLAYER.instantiate()
	player.name = "Player"
	player.position = spawn + Vector3(0, 0.15, 0)
	add_child(player)
	var hud := CanvasLayer.new()
	add_child(hud)
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	prompt.position = Vector2(30, 80)
	prompt.add_theme_font_size_override("font_size", 22)
	hud.add_child(prompt)
	var music := AudioStreamPlayer.new()
	music.name = "DungeonMusic"
	music.stream = preload("res://audio/bone_in_the_walls__level_loop_session.ogg")
	music.volume_db = -14
	add_child(music)
	music.play()

func cell_position(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL, 0, cell.y * CELL)

func build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("172331")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("afbdd2")
	environment.ambient_light_energy = 0.7
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-65, -25, 0)
	sun.light_color = Color("bacce1")
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)

func build_geometry() -> void:
	var library := MeshLibrary.new()
	for i in 2:
		library.create_item(i)
		var size := Vector3(CELL, 0.4, CELL) if i == 0 else Vector3(CELL, 4.0, CELL)
		var offset := Vector3(0, -0.2, 0) if i == 0 else Vector3(0, 2.0, 0)
		var mesh := BoxMesh.new()
		mesh.size = size
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("8c929b") if i == 0 else Color("6e7887")
		material.albedo_texture = preload("res://demo_level/gridmap/gridmap_materials/TinyBrick01_albedo.png")
		material.uv1_triplanar = true
		material.roughness = 0.9
		mesh.material = material
		library.set_item_mesh(i, mesh)
		library.set_item_mesh_transform(i, Transform3D(Basis.IDENTITY, offset))
		var shape := BoxShape3D.new()
		shape.size = size
		library.set_item_shapes(i, [shape, Transform3D(Basis.IDENTITY, offset)])
	var grid := GridMap.new()
	grid.name = "DungeonGeometry"
	grid.mesh_library = library
	grid.cell_size = Vector3(CELL, 1, CELL)
	grid.cell_center_x = false
	grid.cell_center_y = false
	grid.cell_center_z = false
	grid.collision_layer = 1
	add_child(grid)
	for cell: Vector2i in layout.cells:
		grid.set_cell_item(Vector3i(cell.x, 0, cell.y), 0)
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + direction
			if not layout.cells.has(neighbor):
				grid.set_cell_item(Vector3i(neighbor.x, 0, neighbor.y), 1)

func build_navigation() -> void:
	# Bake the exact connected floor footprint, including clearance at its edges.
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "DungeonNavigation"
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.25
	mesh.cell_height = 0.1
	mesh.agent_radius = 0.5
	mesh.agent_max_climb = 0.2
	mesh.agent_height = 1.8
	var faces := PackedVector3Array()
	for cell: Vector2i in layout.cells:
		var center := cell_position(cell)
		var a := center + Vector3(-1, 0, -1)
		var b := center + Vector3(1, 0, -1)
		var c := center + Vector3(1, 0, 1)
		var d := center + Vector3(-1, 0, 1)
		faces.append_array(PackedVector3Array([a, b, c, a, c, d]))
	var source := NavigationMeshSourceGeometryData3D.new()
	source.add_faces(faces, Transform3D.IDENTITY)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	navigation_region.navigation_mesh = mesh
	add_child(navigation_region)

func build_exit() -> void:
	var portal := MeshInstance3D.new()
	portal.name = "ReturnPortal"
	var shape := TorusMesh.new()
	shape.inner_radius = 1.1
	shape.outer_radius = 1.4
	portal.mesh = shape
	portal.position = exit_position + Vector3(0, 1.6, 0)
	portal.rotation.x = PI / 2
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6ce6ff")
	material.emission_enabled = true
	material.emission = Color("25b7e0")
	material.emission_energy_multiplier = 2.5
	portal.material_override = material
	add_child(portal)
	var title := Label3D.new()
	title.text = "RETURN TO REFUGE"
	title.position = exit_position + Vector3(0, 3.6, 0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)

func near_exit() -> bool:
	return is_instance_valid(player) and player.global_position.distance_to(exit_position) < 3.2

func _process(_delta: float) -> void:
	if prompt:
		prompt.text = "[ E ] Return to Refuge" if near_exit() else "SHIFTING DEPTHS  |  Find the return portal"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and near_exit():
		if not player.busy and not player.is_dead and player.current_state == player.state.FREE:
			get_node("/root/GameSession").return_home()
			get_viewport().set_input_as_handled()
