extends Node3D
signal monster_spawned(monster: CharacterBody3D, distance: float)
signal difficulty_changed
signal boss_spawned(boss: CharacterBody3D)
signal round_completed
const MONSTER = preload("res://scenes/monster.tscn")
const BOSS = preload("res://scenes/boss.tscn")
const ARCHER = preload("res://scenes/archer_monster.tscn")
const FLYER = preload("res://scenes/flying_monster.tscn")
@export var archer_unlock_time := 300.0
@export var flyer_unlock_time := 600.0
@export var max_archers := 12
@export var max_flyers := 6
@export var enabled := true
@export_range(1.0, 100.0, 0.5) var spawn_radius := 20.0
@export_range(1.0, 150.0, 0.5) var outer_radius := 26.0
@export_range(0.1, 30.0, 0.1) var spawn_interval := 2.0
@export var initial_count := 6
@export_range(1.0, 600.0, 1.0) var growth_interval := 90.0
@export var max_batch_size := 12
@export var survival_duration := 1200.0
@export var boss_health := 6000.0
var boss_phase := false
var boss_started := false
var completed := false
var boss: CharacterBody3D
@export_range(0.0, 100.0, 1.0) var health_growth_per_minute := 30.0
@export_range(0.0, 100.0, 1.0) var health_growth_curve := 6.0
var survival_time := 0.0
var difficulty_step := 0
## Disable for the real game. Release exports never draw debug helpers.
@export var show_debug_radius := false
var player: CharacterBody3D
var rng := RandomNumberGenerator.new()
var monsters: Array[CharacterBody3D] = []
var countdown := 0.25
var started := false
var ring: MeshInstance3D
var markers: Node3D
var info: Label
var last_distance := 0.0
var total_spawned := 0
func _ready() -> void:
	player = get_parent().get_node("Player")
	rng.randomize()
	ring = MeshInstance3D.new()
	ring.name = "DebugSpawnRadius"
	ring.mesh = ring_mesh(spawn_radius, 0.65, Color(0.0, 0.5, 0.72))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	markers = Node3D.new()
	markers.name = "DebugSpawnMarkers"
	add_child(markers)
	var layer := CanvasLayer.new()
	add_child(layer)
	info = Label.new()
	info.position = Vector2(40, 144)
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_shadow_color", Color.BLACK)
	info.add_theme_constant_override("shadow_offset_x", 1)
	info.add_theme_constant_override("shadow_offset_y", 1)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(info)
	update_debug()
func ring_mesh(radius: float, width: float, color: Color) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for i in range(160):
		var a := TAU * float(i) / 160.0
		var b := TAU * float(i + 1) / 160.0
		var va := Vector3(cos(a), 0, sin(a))
		var vb := Vector3(cos(b), 0, sin(b))
		var inside := radius - width * 0.5
		var outside := radius + width * 0.5
		for vertex in [va * inside, va * outside, vb * outside, va * inside, vb * outside, vb * inside]:
			mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	return mesh
func _physics_process(delta: float) -> void:
	monsters = monsters.filter(func(m): return is_instance_valid(m) and not m.dead and not m.is_queued_for_deletion())
	update_debug()
	if not enabled or completed or not is_instance_valid(player) or get_tree().paused:
		return
	survival_time = minf(survival_time + delta, survival_duration)
	if survival_time >= survival_duration:
		if not boss_phase:
			boss_phase = true
			difficulty_changed.emit()
		if not boss_started:
			_try_spawn_boss()
		return
	var next_step := int(floor(survival_time / maxf(growth_interval, 0.1)))
	if next_step != difficulty_step:
		difficulty_step = next_step
		difficulty_changed.emit()
	for monster in monsters:
		if monster.global_position.distance_to(player.global_position) > 85.0:
			monster.queue_free()
	countdown -= delta
	if countdown > 0.0:
		return
	var count := maxi(1, initial_count) if not started else spawn_batch_size()
	started = true
	for i in range(count):
		if spawn_one() == null:
			break
	countdown = maxf(spawn_interval, 0.1)

func spawn_batch_size() -> int:
	return mini(2 + difficulty_step, maxi(max_batch_size, 1))

func monster_health() -> float:
	# Advance in one-second increments while preserving the minute-based curve.
	var minutes: float = floorf(maxf(survival_time, 0.0)) / 60.0
	return 40.0 + health_growth_per_minute * minutes + health_growth_curve * minutes * minutes
func spawn_one(as_boss: bool = false) -> CharacterBody3D:
	monsters = monsters.filter(func(m): return is_instance_valid(m) and not m.dead and not m.is_queued_for_deletion())
	if not enabled or completed or get_tree().paused or not is_instance_valid(player):
		return null
	if not as_boss and boss_phase:
		return null
	var enemy_type := "boss" if as_boss else pick_monster_type()
	var center := player.global_position
	# Keep the entire 0.4 m collision capsule outside the boundary.
	var inner := maxf(spawn_radius, 1.0) + 0.6
	var outer := maxf(outer_radius + (8.0 if as_boss else 0.0), inner + 0.5)
	for attempt in range(24):
		var angle := rng.randf_range(0, TAU)
		var radius := sqrt(rng.randf_range(inner * inner, outer * outer))
		var candidate := center + Vector3(cos(angle), 0, sin(angle)) * radius
		var ground_query := PhysicsRayQueryParameters3D.create(candidate + Vector3(0, 8, 0), candidate - Vector3(0, 32, 0), 1, [player.get_rid()])
		var ground := get_world_3d().direct_space_state.intersect_ray(ground_query)
		if ground.is_empty() or ground["normal"].y < 0.8 or ground["collider"] is CharacterBody3D:
			continue
		candidate = ground["position"] + Vector3(0, 2.24 if enemy_type == "flyer" else 0.04, 0)
		var crowded := false
		for monster in monsters:
			if monster.global_position.distance_to(candidate) < 1.5:
				crowded = true
				break
		if crowded:
			continue
		var shape := CapsuleShape3D.new()
		shape.radius = 0.9 if as_boss else 0.45
		shape.height = 3.8 if as_boss else 1.9
		var occupancy := PhysicsShapeQueryParameters3D.new()
		occupancy.shape = shape
		occupancy.transform = Transform3D(Basis.IDENTITY, candidate + Vector3(0, 1.9 if as_boss else 0.95, 0))
		occupancy.collision_mask = 1
		if not get_world_3d().direct_space_state.intersect_shape(occupancy, 1).is_empty():
			continue
		var scene: PackedScene = BOSS if as_boss else (ARCHER if enemy_type == "archer" else (FLYER if enemy_type == "flyer" else MONSTER))
		var monster: CharacterBody3D = scene.instantiate()
		monster.player = player
		var health_scale := 0.70 if enemy_type == "archer" else (0.60 if enemy_type == "flyer" else 1.0)
		monster.max_health = boss_health if as_boss else monster_health() * health_scale
		monster.position = to_local(candidate)
		add_child(monster)
		monsters.append(monster)
		last_distance = Vector2(candidate.x - center.x, candidate.z - center.z).length()
		total_spawned += 1
		if debug_visible():
			spawn_marker(candidate, last_distance)
		monster_spawned.emit(monster, last_distance)
		return monster
	return null
func debug_visible() -> bool:
	return show_debug_radius and OS.is_debug_build()
func update_debug() -> void:
	if not is_instance_valid(ring):
		return
	var show := debug_visible()
	ring.visible = show
	markers.visible = show
	info.visible = false
	if is_instance_valid(player):
		ring.global_position = Vector3(player.global_position.x, 0.035, player.global_position.z)
	info.text = "SPAWN DEBUG\nCyan ring: %.0f m | Spawn outside ring\nAlive: %d (unlimited) | Last spawn: %.1f m\nMonsters can walk inside after spawning" % [spawn_radius, monsters.size(), last_distance]
func spawn_marker(point: Vector3, distance: float) -> void:
	var marker := MeshInstance3D.new()
	marker.mesh = ring_mesh(0.85, 0.12, Color(1, 0.65, 0.1))
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	markers.add_child(marker)
	marker.global_position = point + Vector3(0, 0.025, 0)
	var label := Label3D.new()
	label.text = "SPAWN %.1f m" % distance
	label.font_size = 48
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.8
	marker.add_child(label)
	get_tree().create_timer(2.0, false).timeout.connect(marker.queue_free)
func reset_encounter() -> void:
	for monster in monsters:
		if is_instance_valid(monster):
			monster.queue_free()
	monsters.clear()
	started = false
	boss_phase = false
	boss_started = false
	completed = false
	boss = null
	survival_time = 0.0
	difficulty_step = 0
	countdown = 2.0
	difficulty_changed.emit()




func _try_spawn_boss() -> void:
	boss = spawn_one(true)
	if not is_instance_valid(boss):
		return
	boss_started = true
	boss.defeated.connect(_on_boss_defeated)
	boss_spawned.emit(boss)

func _on_boss_defeated() -> void:
	if not boss_phase or completed:
		return
	completed = true
	for monster in monsters:
		if is_instance_valid(monster) and monster != boss:
			monster.queue_free()
	round_completed.emit()


func monster_spawn_weights() -> Dictionary:
	var weights := {"melee": 100.0, "archer": 0.0, "flyer": 0.0}
	if survival_time >= flyer_unlock_time:
		weights = {"melee":74.0,"archer":18.0,"flyer":8.0}
	elif survival_time >= archer_unlock_time:
		weights = {"melee":80.0,"archer":20.0,"flyer":0.0}
	var archers := 0
	var flyers := 0
	for monster in monsters:
		if not is_instance_valid(monster) or monster.dead or monster.is_queued_for_deletion():
			continue
		if monster.is_in_group("archer_monsters"):
			archers += 1
		if monster.is_in_group("flying_monsters"):
			flyers += 1
	if archers >= max_archers:
		weights["archer"] = 0.0
	if flyers >= max_flyers:
		weights["flyer"] = 0.0
	return weights
func pick_monster_type() -> String:
	var weights := monster_spawn_weights()
	var total := 0.0
	for weight in weights.values():
		total += float(weight)
	var choice := rng.randf() * total
	for enemy_type in weights:
		if weights[enemy_type] <= 0.0:
			continue
		choice -= float(weights[enemy_type])
		if choice <= 0.0:
			return enemy_type
	return "melee"



