extends CharacterBody3D
@export var max_health := 30.0
@export var move_speed := 2.6
@export var attack_damage := 8.0
@export var attack_interval := 1.2
var player: CharacterBody3D
var health := 30.0
var dead := false
var attack_timer := 0.6
var hit_flash := 0.0
@onready var model: Node3D = $Model
@onready var health_label: Label3D = $Health
func _ready() -> void:
	health = max_health
	add_to_group("monsters")
	refresh()
func aim_point() -> Vector3:
	return global_position + Vector3(0, 1.25, 0)
func take_damage(amount: float) -> int:
	if dead or amount <= 0:
		return 0
	health = maxf(0, health - amount)
	hit_flash = 0.12
	model.scale = Vector3.ONE * 1.12
	refresh()
	if health <= 0:
		dead = true
		collision_layer = 0
		hide()
		queue_free()
		return 2
	return 1
func refresh() -> void:
	health_label.text = "%d / %d" % [ceili(health), ceili(max_health)]
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player):
		return
	hit_flash = maxf(0, hit_flash - delta)
	if hit_flash == 0:
		model.scale = Vector3.ONE
	attack_timer = maxf(0, attack_timer - delta)
	var offset := player.global_position - global_position
	var flat := Vector3(offset.x, 0, offset.z)
	var distance := flat.length()
	var direction := flat.normalized()
	if distance > 0.05:
		rotation.y = atan2(-direction.x, -direction.z)
	velocity.x = direction.x * move_speed if distance > 1.1 else 0.0
	velocity.z = direction.z * move_speed if distance > 1.1 else 0.0
	velocity.y -= 25.0 * delta
	move_and_slide()
	if global_position.y < -25:
		queue_free()
		return
	if distance <= 1.55 and absf(offset.y) < 1.4 and attack_timer <= 0:
		var query := PhysicsRayQueryParameters3D.create(aim_point(), player.global_position + Vector3.UP, 1, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit["collider"] == player:
			player.receive_damage(attack_damage)
			attack_timer = attack_interval

