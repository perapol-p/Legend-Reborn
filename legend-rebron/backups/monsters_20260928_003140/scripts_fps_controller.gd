extends CharacterBody3D
@export var move_speed := 9.0
@export var sprint_multiplier := 1.5
@export var jump_speed := 9.0
@export var gravity := 25.0
@export var ground_acceleration := 70.0
@export var air_acceleration := 22.0
@export var dash_speed := 25.0
@export var dash_duration := 0.16
@export var dash_cooldown := 0.65
var input_enabled := true
var run: Node
var dash_remaining := 0.0
var dash_recovery := 0.0
var dash_direction := Vector3.ZERO
var coyote_remaining := 0.0
var jump_buffer := 0.0
var spawn_position := Vector3(0, 0.1, 12)
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
func bind_run(model: Node) -> void:
	run = model
func speed_multiplier() -> float:
	if run == null:
		return 1.0
	return float(run.stats()["speed"]) / float(run.catalog.data["base_stats"]["speed"])
func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		apply_look(event.relative)
func apply_look(motion: Vector2) -> void:
	var sensitivity := lerpf(0.0004, 0.004, GameData.mouse_sensitivity)
	rotation.y -= motion.x * sensitivity
	var direction := 1.0 if GameData.invert_y else -1.0
	head.rotation.x = clampf(head.rotation.x + motion.y * sensitivity * direction, deg_to_rad(-89), deg_to_rad(89))
func _physics_process(delta: float) -> void:
	if global_position.y < -20:
		respawn()
	var axis := Vector2.ZERO
	if input_enabled:
		axis = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	coyote_remaining = 0.1 if is_on_floor() else maxf(0.0, coyote_remaining - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if input_enabled and Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	if not input_enabled:
		jump_buffer = 0.0
	if jump_buffer > 0 and coyote_remaining > 0:
		velocity.y = jump_speed
		jump_buffer = 0
		coyote_remaining = 0
	else:
		velocity.y -= gravity * delta
	var direction: Vector3 = global_basis * Vector3(axis.x, 0, axis.y)
	direction.y = 0
	direction = direction.normalized()
	dash_recovery = maxf(0.0, dash_recovery - delta)
	var scale_speed := speed_multiplier()
	if input_enabled and Input.is_action_just_pressed("dash") and dash_recovery <= 0:
		dash_direction = direction if direction.length_squared() > 0.01 else -global_basis.z
		dash_remaining = dash_duration
		dash_recovery = dash_cooldown
	if dash_remaining > 0 and input_enabled:
		dash_remaining = maxf(0.0, dash_remaining - delta)
		velocity.x = dash_direction.x * dash_speed * scale_speed
		velocity.z = dash_direction.z * dash_speed * scale_speed
		velocity.y = 0
	else:
		dash_remaining = 0
		var target_speed := move_speed * scale_speed
		if input_enabled and Input.is_action_pressed("sprint"):
			target_speed *= sprint_multiplier
		var acceleration := ground_acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta * scale_speed)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta * scale_speed)
	move_and_slide()
	camera.fov = lerpf(camera.fov, 98.0 if dash_remaining > 0 else 90.0, 1.0 - exp(-8.0 * delta))
func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	dash_remaining = 0
	dash_recovery = 0
	jump_buffer = 0
