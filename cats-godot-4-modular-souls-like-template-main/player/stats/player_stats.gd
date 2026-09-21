extends Node
## Runtime adapter for the existing souls character controller.
signal stamina_changed
signal exhausted
var player: CharacterBody3D
var health: Node
var progression: Node
var stamina: float = 100.0
var recovery_delay: float = 0.0
var original_speed: float = 4.0

func _ready() -> void:
	player = get_parent()
	health = player.health_system
	progression = get_node("/root/CharacterProgression")
	original_speed = player.default_speed
	progression.changed.connect(apply_build)
	apply_build()
	health.current_health = health.total_health
	health.health_updated.emit(health.current_health)
	stamina = progression.value("Stamina")

func apply_build() -> void:
	var previous_max: float = health.total_health
	health.total_health = int(progression.value("Hp"))
	# Preserve missing health, so increasing HP adds its new capacity immediately.
	if health.current_health > 0:
		health.current_health = minf(health.total_health, health.current_health + health.total_health - previous_max)
	health.health_updated.emit(health.current_health)
	player.default_speed = original_speed * movement_multiplier()
	if player.current_state == player.state.FREE:
		player.speed = player.default_speed
	stamina = minf(stamina, progression.value("Stamina"))
	stamina_changed.emit()

func movement_multiplier() -> float:
	return progression.value("Spd") / 100.0

func attack_multiplier() -> float:
	return progression.value("Atk") / 10.0

func incoming_damage(power: float) -> float:
	return power * 20.0 * 100.0 / (100.0 + progression.value("Def"))

func spend_stamina(amount: float) -> bool:
	if player.is_dead or stamina < amount:
		exhausted.emit()
		return false
	stamina = maxf(0.0, stamina - amount)
	recovery_delay = 0.8
	stamina_changed.emit()
	return true

func _physics_process(delta: float) -> void:
	if player.is_dead:
		return
	if player.sprinting:
		if not spend_stamina(18.0 * delta):
			player.end_sprint()
	else:
		recovery_delay = maxf(0.0, recovery_delay - delta)
		if recovery_delay <= 0.0:
			var recovery: float = 24.0 * delta * (0.35 if player.guarding else 1.0)
			stamina = minf(progression.value("Stamina"), stamina + recovery)
			stamina_changed.emit()
