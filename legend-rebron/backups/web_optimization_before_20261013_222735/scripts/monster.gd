extends CharacterBody3D
signal defeated
@export var max_health := 30.0
@export var move_speed := 2.6
@export var speed_growth_per_minute := 0.10
var alive_seconds := 0.0
var base_move_speed := 0.0
var pressure_multiplier := 1.0
var base_attack_damage := 0.0
var base_attack_interval := 0.0
@export var attack_damage := 8.0
@export var attack_interval := 1.2
@export var attack_range := 1.55
@export var stop_distance := 1.1
@export var climb_speed := 2.8
var climbing := false
var player: CharacterBody3D
var health := 30.0
var dead := false
var attack_timer := 0.6
var hit_flash := 0.0
var zombie_visual: Node3D
var melee_visual: Node3D
var death_visual: Node3D
var damage_flash: Node
@onready var model: Node3D = $Model
@onready var health_label: Label3D = $Health
func _ready() -> void:
	health = max_health
	base_move_speed = move_speed
	base_attack_damage = attack_damage
	base_attack_interval = attack_interval
	add_to_group("monsters")
	# Derived ranged monsters and the boss keep their existing model.
	if get_script().resource_path == "res://scripts/monster.gd":
		for child in model.get_children():
			if child is GeometryInstance3D:
				child.hide()
		zombie_visual = Node3D.new()
		zombie_visual.set_script(preload("res://scripts/zombie_visual.gd"))
		model.add_child(zombie_visual)
		death_visual = zombie_visual
		melee_visual = zombie_visual
	damage_flash = preload("res://scripts/enemy_hit_flash.gd").new()
	add_child(damage_flash)
	damage_flash.bind_model(model)
	refresh()
func aim_point() -> Vector3:
	return global_position + Vector3(0, 1.25 * scale.y, 0)
func take_damage(amount: float) -> int:
	if dead or amount <= 0:
		return 0
	health = maxf(0, health - amount)
	hit_flash = 0.12
	damage_flash.flash()
	refresh()
	if health <= 0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		defeated.emit()
		if is_instance_valid(death_visual):
			model.scale = Vector3.ONE
			health_label.hide()
			death_visual.die()
			var death_time: float = death_visual.death_duration() if death_visual.has_method("death_duration") else 0.85
			get_tree().create_timer(death_time, false).timeout.connect(queue_free)
		else:
			hide()
			queue_free()
		return 2
	return 1
func refresh() -> void:
	health_label.text = "%d / %d" % [ceili(health), ceili(max_health)]
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player):
		return
	advance_age(delta)
	hit_flash = maxf(0, hit_flash - delta)
	if hit_flash == 0:
		model.scale = Vector3.ONE
	attack_timer = maxf(0, attack_timer - delta)
	var offset := player.global_position - global_position
	var flat := Vector3(offset.x, 0, offset.z)
	var distance := flat.length()
	var direction := movement_direction(player.global_position)
	if distance > 0.05:
		rotation.y = atan2(-direction.x, -direction.z)
	velocity.x = direction.x * move_speed if distance > stop_distance or offset.y > 1.1 else 0.0
	velocity.z = direction.z * move_speed if distance > stop_distance or offset.y > 1.1 else 0.0
	velocity.y -= 25.0 * delta
	apply_climbing(delta)
	move_and_slide()
	if is_instance_valid(melee_visual):
		melee_visual.update_locomotion(Vector2(velocity.x, velocity.z).length() > 0.1, move_speed)
	if global_position.y < -25:
		queue_free()
		return
	if distance <= attack_range and absf(offset.y) < 1.4 and attack_timer <= 0:
		var query := PhysicsRayQueryParameters3D.create(aim_point(), player.global_position + Vector3.UP, 1, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit["collider"] == player:
			if is_instance_valid(melee_visual):
				melee_visual.attack()
			player.receive_damage(attack_damage, global_position)
			attack_timer = attack_interval




func advance_age(delta: float) -> void:
	if dead or get_tree().paused:
		return
	alive_seconds += maxf(delta, 0.0)
	move_speed = base_move_speed * (1.0 + speed_growth_per_minute * alive_seconds / 60.0) * pressure_multiplier
	attack_damage = base_attack_damage * pressure_multiplier
	attack_interval = base_attack_interval / maxf(pressure_multiplier, 1.0)


func movement_direction(target: Vector3) -> Vector3:
	# Pursue elevated players directly over walls and other monsters.
	var direct := target - global_position
	direct.y = 0.0
	if target.y > global_position.y + 0.6 and direct.length_squared() > 0.001:
		return direct.normalized()
	var current_scene = get_tree().current_scene
	var arena = current_scene.get_node_or_null("Arena") if is_instance_valid(current_scene) else null
	if arena == null:
		arena = player.get_parent().get_node_or_null("Arena")
	var destination: Vector3 = arena.movement_target(self,target) if arena != null and arena.has_method("movement_target") else target
	var direction := destination - global_position
	direction.y = 0.0
	direction = direction.normalized()
	return arena.steer_direction(self,direction) if arena != null and arena.has_method("steer_direction") else direction

# Use the body shape to detect supports. Upward movement remains collision-based.
func apply_climbing(delta: float) -> void:
	climbing = false
	if dead or not is_instance_valid(player):
		return
	if global_position.y > player.global_position.y + 0.9:
		return
	var forward := Vector3(velocity.x,0,velocity.z)
	if forward.length_squared() < 0.01:
		return
	var contact := KinematicCollision3D.new()
	if not test_move(global_transform,forward.normalized() * (0.45 * scale.x),contact):
		return
	var support = contact.get_collider()
	if support == player or contact.get_normal().y > 0.85:
		return
	if support is CharacterBody3D:
		if not support.is_in_group("monsters") or support.dead:
			return
		if support.is_in_group("flying_monsters"):
			return
	elif not support is StaticBody3D:
		return
	if test_move(global_transform,Vector3.UP * maxf(0.06,climb_speed * delta)):
		return
	climbing = true
	velocity.y = climb_speed
