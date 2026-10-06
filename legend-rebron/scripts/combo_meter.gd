extends Node
signal changed
const RANKS = ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"]
@export var points_per_rank: int = 20
@export var decay_seconds: float = 3.0
var points: int = 0
var remaining: float = 0.0
func rank_index() -> int:
	return -1 if points == 0 else mini(int((points - 1) / points_per_rank), RANKS.size() - 1)
func register_hit() -> void:
	add_points(1)
func register_kill() -> void:
	add_points(3)
func add_points(amount: int) -> void:
	points = maxi(points + amount, 0)
	remaining = decay_seconds if points > 0 else 0.0
	changed.emit()
func reset() -> void:
	points = 0
	remaining = 0.0
	changed.emit()
func advance(delta: float) -> void:
	if points == 0:
		return
	remaining -= delta
	while remaining <= 0.0 and points > 0:
		points = maxi(points - points_per_rank, 0)
		if points > 0:
			remaining += decay_seconds
		else:
			remaining = 0.0
	changed.emit()
func _process(delta: float) -> void:
	advance(delta)

