extends RefCounted
## Godot 4 port of the room/separation/spanning-tree/corridor pipeline in
## Godot-Simple-Dungeon-Generator (2019, MIT). See third_party/LICENSE.
## Uses a complete candidate graph so collinear rooms also remain connected.
const ROOM_COUNT := 18
const KEEP_ROOMS := 8
var rooms: Array[Rect2i] = []
var links: Array[Vector2i] = []
var cells: Dictionary = {}
var rng := RandomNumberGenerator.new()

func generate(seed_value: int) -> void:
	rng.seed = seed_value
	rooms.clear()
	links.clear()
	cells.clear()
	for i in ROOM_COUNT:
		var size := Vector2i(rng.randi_range(5, 9), rng.randi_range(5, 9))
		var angle := rng.randf() * TAU
		var radius := sqrt(rng.randf()) * 12.0
		rooms.append(Rect2i(Vector2i(Vector2(cos(angle), sin(angle)) * radius), size))
	# Bound separation work; deterministic fallback guarantees disjoint rooms.
	for iteration in 256:
		var moved := false
		for i in rooms.size():
			for j in range(i + 1, rooms.size()):
				if rooms[i].grow(2).intersects(rooms[j]):
					var difference := rooms[j].get_center() - rooms[i].get_center()
					if absi(difference.x) >= absi(difference.y):
						rooms[j].position.x += 1 if difference.x >= 0 else -1
					else:
						rooms[j].position.y += 1 if difference.y >= 0 else -1
					moved = true
		if not moved:
			break
	for j in rooms.size():
		var overlap := true
		while overlap:
			overlap = false
			for i in j:
				if rooms[i].grow(2).intersects(rooms[j]):
					rooms[j].position.x = rooms[i].end.x + 3
					overlap = true
	rooms.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.get_area() > b.get_area())
	rooms.resize(KEEP_ROOMS)
	rooms.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.get_center().length_squared() < b.get_center().length_squared())
	var connected: Array[int] = [0]
	while connected.size() < rooms.size():
		var closest := INF
		var pair := Vector2i.ZERO
		for a in connected:
			for b in rooms.size():
				if b in connected:
					continue
				var distance := Vector2(rooms[a].get_center()).distance_squared_to(Vector2(rooms[b].get_center()))
				if distance < closest:
					closest = distance
					pair = Vector2i(a, b)
		links.append(pair)
		connected.append(pair.y)
	for a in rooms.size():
		for b in range(a + 1, rooms.size()):
			if Vector2i(a, b) not in links and Vector2i(b, a) not in links and rng.randf() < 0.08:
				links.append(Vector2i(a, b))
	for room in rooms:
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				cells[Vector2i(x, y)] = true
	for link in links:
		var point := rooms[link.x].get_center()
		var end := rooms[link.y].get_center()
		var horizontal_first := rng.randf() < 0.5
		carve(point)
		while point != end:
			if (horizontal_first and point.x != end.x) or point.y == end.y:
				point.x += signi(end.x - point.x)
			else:
				point.y += signi(end.y - point.y)
			carve(point)

func carve(point: Vector2i) -> void:
	for x in range(-1, 2):
		for y in range(-1, 2):
			cells[point + Vector2i(x, y)] = true
