extends SceneTree
const Layout = preload("res://dungeon/layout_generator.gd")
var failures := 0
var session: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 600:
		await process_frame
		if is_instance_valid(session.player) and not session.transitioning:
			break
	await create_timer(0.6).timeout

func run() -> void:
	var signatures := {}
	for seed_value in range(1, 101):
		var a = Layout.new()
		var b = Layout.new()
		a.generate(seed_value)
		b.generate(seed_value)
		check(a.rooms == b.rooms and a.cells == b.cells, "Seed must reproduce layout")
		signatures[str(a.rooms)] = true
		var start: Vector2i = a.rooms[0].get_center()
		var visited := {start: true}
		var queue: Array[Vector2i] = [start]
		var cursor := 0
		while cursor < queue.size():
			var point := queue[cursor]
			cursor += 1
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = point + offset
				if a.cells.has(next) and not visited.has(next):
					visited[next] = true
					queue.append(next)
		check(visited.size() == a.cells.size(), "Every floor cell must be reachable")
		for i in a.rooms.size():
			for j in range(i + 1, a.rooms.size()):
				check(not a.rooms[i].intersects(a.rooms[j]), "Rooms must not overlap")
	check(signatures.size() == 100, "Different seeds produce different layouts")
	print("LAYOUT: 100 seeds checked")
	session = root.get_node("GameSession")
	session.persistence_enabled = false
	session.progression().persistence_enabled = false
	session.begin_new_game()
	await settle()
	session.player.health_system.current_health = 79
	session.player.inventory_system.inventory[0].count = 2
	check(session.enter_dungeon(), "Home portal accepts travel")
	check(not session.enter_dungeon(), "Repeated entry during travel is rejected")
	await settle()
	check(current_scene.scene_file_path == session.WORLD, "Portal loads generated dungeon")
	var first_seed: int = current_scene.generation_seed
	check(session.player.is_on_floor(), "Spawn has working floor collision")
	check(session.player.health_system.current_health == 79, "Travel preserves health")
	check(session.player.inventory_system.inventory[0].count == 2, "Travel preserves items")
	check(get_nodes_in_group("targets").size() == 7, "Generated dungeon contains guardians")
	check(current_scene.navigation_region.navigation_mesh.get_polygon_count() > 0, "Navigation mesh is baked")
	var map: RID = current_scene.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, session.player.global_position, current_scene.exit_position, true)
	check(path.size() > 1, "Navigation connects spawn to exit")
	var snapshot: Dictionary = session.capture_world()
	check(snapshot.dungeon_seed == first_seed, "Save records expedition seed")
	# A death/reload retains this layout.
	check(reload_current_scene() == OK, "Current expedition can reload")
	await settle()
	check(current_scene.generation_seed == first_seed, "Respawn keeps current layout")
	session.player.global_position = current_scene.exit_position + Vector3(0, 0.1, 0)
	session.player.busy = false
	session.player.current_state = session.player.state.FREE
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	current_scene._unhandled_input(event)
	await settle()
	check(current_scene.scene_file_path == session.HOME, "Exit portal returns Home")
	check(session.enter_dungeon(), "Can enter another expedition")
	await settle()
	check(current_scene.generation_seed != first_seed, "Each portal entry gets a fresh seed")
	check(session.player.is_on_floor(), "Fresh expedition starts safely")
	print("RESULT: dungeon tests, %d failures" % failures)
	quit(1 if failures else 0)
