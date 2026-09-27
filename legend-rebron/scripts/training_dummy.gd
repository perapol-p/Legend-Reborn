extends StaticBody3D
@export var max_health := 100.0
var health := 100.0
var dead := false
@onready var label: Label3D = $Health
func _ready() -> void:
	health = max_health
	refresh()
func aim_point() -> Vector3:
	return global_position + Vector3(0, 1.35, 0)
## 0 = ignored, 1 = damaged, 2 = killed. Other enemies can use this contract.
func take_damage(amount: float) -> int:
	if dead or amount <= 0.0:
		return 0
	health = maxf(0.0, health - amount)
	refresh()
	if health <= 0.0:
		dead = true
		collision_layer = 0
		hide()
		queue_free()
		return 2
	return 1
func refresh() -> void:
	label.text = "TARGET  %d / %d" % [ceili(health), ceili(max_health)]

