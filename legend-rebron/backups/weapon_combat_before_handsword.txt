extends Node3D
## Gameplay lives here; replace only the Models in scenes/weapons to swap art.
const PROJECTILE = preload("res://scripts/weapon_projectile.gd")
const TORNADO = preload("res://scripts/weapon_tornado.gd")
const CHARGE_TARGET = preload("res://scripts/gun_charge_target.gd")
const TARGET = preload("res://scenes/training_dummy.tscn")
const WEAPONS = {
	"sword": {"cooldown": 0.55, "damage": 1.3, "reach": 3.2, "delay": 0.16},
	"katana": {"cooldown": 0.34, "damage": 0.85, "reach": 3.5, "delay": 0.10},
	"gun": {"cooldown": 0.22, "damage": 1.0, "reach": 150.0, "delay": 0.0},
	"bow": {"cooldown": 0.8, "damage": 2.0, "speed": 38.0, "delay": 0.20},
	"spellbook": {"cooldown": 0.65, "damage": 1.6, "speed": 22.0, "delay": 0.18}
}
const ORDER = ["sword", "katana", "gun", "bow", "spellbook"]
var player: CharacterBody3D
var camera: Camera3D
var run: Node
var combo: Node
var view: Node3D
var weapon_id := ""
var cooldown := 0.0
var pending := -1.0
var elapsed := 0.0
var motion_time := 0.0
var attack_active := false
var dummy: Node3D
var feedback: Label
var feedback_time := 0.0
var attack_held := false
@export_range(0.0, 1.0, 0.01) var charge_target_chance := 0.35
var charge_ready := false
var charge_time := 0.0
var empowered := 0.0
var gun_ammo := 12
var gun_reload := 0.0
var bow_ammo := 4
var bow_reload := 0.0
var rpg_ready := false
var special_cooldown := 0.0
var ability_status: Label
var ammo_label: Label
var ammo_hint: Label
var charge_meter: Control
var volley_queue: Array[Dictionary] = []
var attack_serial := 0
var projectiles_fired := 0
var tornadoes_created := 0

func bind_combat(body: CharacterBody3D, model: Node, meter: Node) -> void:
	player = body
	camera = get_parent() as Camera3D
	run = model
	combo = meter
	var layer := CanvasLayer.new()
	add_child(layer)
	feedback = Label.new()
	layer.add_child(feedback)
	feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	feedback.offset_left = -120
	feedback.offset_right = 120
	feedback.offset_top = 28
	feedback.offset_bottom = 52
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback.add_theme_constant_override("shadow_offset_y", 2)
	ability_status = Label.new()
	layer.add_child(ability_status)
	ability_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	ability_status.offset_left = -360
	ability_status.offset_right = 360
	ability_status.offset_top = 110
	ability_status.offset_bottom = 138
	ability_status.add_theme_font_size_override("font_size", 14)
	ability_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_status.add_theme_color_override("font_shadow_color", Color.BLACK)
	ability_status.add_theme_constant_override("shadow_offset_y", 1)
	ammo_label = Label.new()
	layer.add_child(ammo_label)
	ammo_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.offset_left = -340
	ammo_label.offset_right = -40
	ammo_label.offset_top = -150
	ammo_label.offset_bottom = -88
	ammo_label.add_theme_font_size_override("font_size", 44)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_label.add_theme_color_override("font_color", Color("eee6d1"))
	ammo_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	ammo_label.add_theme_constant_override("shadow_offset_x", 2)
	ammo_label.add_theme_constant_override("shadow_offset_y", 2)
	ammo_hint = Label.new()
	layer.add_child(ammo_hint)
	ammo_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_hint.offset_left = -420
	ammo_hint.offset_right = -40
	ammo_hint.offset_top = -86
	ammo_hint.offset_bottom = -46
	ammo_hint.add_theme_font_size_override("font_size", 17)
	ammo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	ammo_hint.add_theme_constant_override("shadow_offset_y", 2)
	charge_meter = preload("res://scripts/charge_meter.gd").new()
	charge_meter.combat = self
	layer.add_child(charge_meter)
	equip(str(run.catalog.data["character_weapons"].get(run.character_name, "sword")))

func can_act() -> bool:
	return is_instance_valid(player) and player.input_enabled and not get_tree().paused and not GameData.rebinding_active

func equip(id: String) -> void:
	if not WEAPONS.has(id):
		return
	pending = -1.0
	attack_active = false
	attack_held = false
	charge_time = 0.0
	empowered = 0.0
	volley_queue.clear()
	charge_ready = false
	for target in get_tree().get_nodes_in_group("gun_charge_targets"):
		if target.source == self:
			target.queue_free()
	weapon_id = id
	if is_instance_valid(view):
		remove_child(view)
		view.queue_free()
	view = load("res://scenes/weapons/" + id + ".tscn").instantiate()
	add_child(view)
	run.equipped_weapon_id = id
	run.changed.emit()
	update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not can_act() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("reload") and not event.is_echo():
		try_reload()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		attack_held = event.pressed
		if event.pressed:
			if weapon_id == "gun" and weapon_level() >= 3 and charge_ready:
				charge_time = 0.0
			else:
				try_attack()
		elif weapon_id == "gun" and weapon_level() >= 3 and charge_ready:
			release_charge()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		try_special()
		get_viewport().set_input_as_handled()
func try_reload() -> bool:
	if not can_act() or weapon_id != "gun" or gun_reload > 0.0 or gun_ammo >= 12:
		return false
	gun_reload = 1.4
	pending = -1.0
	attack_active = false
	attack_held = false
	charge_time = 0.0
	empowered = 0.0
	update_status()
	return true
func try_attack() -> bool:
	if not can_act() or cooldown > 0.0 or (weapon_id == "gun" and gun_reload > 0.0 and empowered <= 0.0) or (weapon_id == "bow" and weapon_level() < 5 and bow_reload > 0.0):
		return false
	cooldown = attack_cooldown()
	pending = minf(float(WEAPONS[weapon_id]["delay"]), cooldown * 0.3)
	attack_serial += 1
	elapsed = 0.0
	attack_active = true
	if pending == 0.0:
		pending = -1.0
		resolve_attack()
	return true

func _physics_process(delta: float) -> void:
	if run == null:
		return
	cooldown = maxf(0.0, cooldown - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	empowered = maxf(0.0, empowered - delta)
	if gun_reload > 0.0:
		gun_reload = maxf(0.0, gun_reload - delta)
		if gun_reload == 0.0:
			gun_ammo = 12
	if bow_reload > 0.0:
		bow_reload = maxf(0.0, bow_reload - delta)
		if bow_reload == 0.0:
			bow_ammo = 4
	if weapon_level() >= 5 and weapon_id == "bow":
		bow_reload = 0.0
		bow_ammo = 4
	if can_act():
		if attack_held and weapon_id == "gun" and weapon_level() >= 3 and charge_ready and gun_reload <= 0.0:
			charge_time = minf(1.5, charge_time + delta)
		elif (attack_held and (weapon_id == "gun" or (weapon_id == "sword" and weapon_level() >= 4) or (weapon_id == "bow" and weapon_level() >= 5))) or (weapon_id == "gun" and empowered > 0.0):
			try_attack()
	update_status()
	for volley in volley_queue.duplicate():
		volley["time"] -= delta
		if volley["time"] <= 0.0:
			volley_queue.erase(volley)
			if can_act() and weapon_id == "katana":
				tornado_round(int(volley["count"]), float(volley["damage"]))
	feedback_time = maxf(0.0, feedback_time - delta)
	feedback.visible = feedback_time > 0.0
	if not can_act():
		pending = -1.0
		attack_active = false
		attack_held = false
		charge_time = 0.0
		empowered = 0.0
		volley_queue.clear()
	if pending >= 0.0:
		pending -= delta
		if pending <= 0.0:
			pending = -1.0
			resolve_attack()
	if not is_instance_valid(view):
		return
	motion_time += delta * 9.0
	var walking := minf(Vector2(player.velocity.x, player.velocity.z).length() / 9.0, 1.0)
	view.position = Vector3(sin(motion_time) * 0.012, absf(cos(motion_time)) * 0.012, 0) * walking
	view.rotation = Vector3.ZERO
	if attack_active:
		elapsed += delta
		var t := clampf(elapsed / attack_cooldown(), 0, 1)
		var swing := sin(t * PI)
		match weapon_id:
			"sword", "katana":
				view.rotation = Vector3(-0.25, -0.65, -0.85) * swing
				view.position += Vector3(-0.22, 0.02, -0.18) * swing
			"gun":
				view.position.z += 0.10 * pow(1.0 - t, 3.0)
				view.rotation.x = 0.12 * pow(1.0 - t, 3.0)
			"bow":
				view.position.z += 0.12 * swing
				view.rotation.z = -0.08 * swing
			"spellbook":
				view.position.y += 0.10 * swing
				view.rotation.x = -0.18 * swing
		if t >= 1.0:
			attack_active = false

func ray(from: Vector3, to: Vector3, mask: int = 1) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, [player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func resolve_attack() -> void:
	if not can_act():
		return
	var level := weapon_level()
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	if weapon_id == "sword":
		if level == 1:
			melee_attack(3.2)
		else:
			fire_projectile("sword_wave", forward, roll_damage(), 14.0, 0.4 if level == 2 else 1.05, true)
	elif weapon_id == "katana":
		melee_attack(3.5)
		var dash_scale := 1.5 if level >= 3 else 1.0
		player.dash_direction = -player.global_basis.z
		player.dash_remaining = player.dash_duration * dash_scale
		player.dash_recovery = player.dash_cooldown
		if level >= 2:
			var count := 3 if level >= 5 else (2 if level >= 4 else 1)
			var rounds := 5 if level >= 5 else (2 if level >= 4 else 1)
			var damage := roll_damage() * 0.4
			tornado_round(count, damage)
			for i in range(1, rounds):
				volley_queue.append({"time": float(i) * 0.2, "count": count, "damage": damage})
	elif weapon_id == "gun":
		if empowered <= 0.0:
			if gun_ammo <= 0:
				return
			gun_ammo -= 1
			if gun_ammo == 0:
				gun_reload = 1.4
		var hit := ray(origin, origin + forward * 150.0, 3)
		var end: Vector3 = origin + forward * 150.0 if hit.is_empty() else hit["position"]
		tracer(origin + camera.global_basis * Vector3(0.26, -0.18, -0.6), end)
		if not hit.is_empty():
			if hit["collider"].has_method("collect_charge"):
				hit["collider"].collect_charge(self)
				return
			var damage := roll_damage()
			deal_hit(hit["collider"], damage, "gun", true)
			if level >= 5:
				explode(end - forward * 0.06, 3.0, damage * 0.7, hit["collider"])
	elif weapon_id == "bow":
		if level < 5:
			if bow_ammo <= 0:
				return
			bow_ammo -= 1
			if bow_ammo == 0:
				bow_reload = 1.3
		var count := 1 if level == 1 else (3 if level == 2 else 6)
		for row in range(2 if level >= 4 else 1):
			for i in range(count):
				var angle := (float(i) - float(count - 1) * 0.5) * 0.025
				# Paired upper/lower volleys stay close enough to hit humanoid targets.
				var pitch := (0.015 if row == 0 else -0.015) if level >= 4 else 0.0
				var direction := (forward + camera.global_basis.x * angle + camera.global_basis.y * pitch).normalized()
				fire_projectile("bow", direction, roll_damage(), 38.0, 0.04, level >= 3)
	else:
		if level < 3:
			fire_projectile("magic_wave", forward, roll_damage(), 22.0, 0.15 if level == 1 else 0.9, false)
		else:
			spawn_tornado(aim_point(12.0), roll_damage() * 0.45, 3.5, 2.5)
			if level >= 5:
				for i in range(3):
					var direction := (forward + camera.global_basis.x * float(i - 1) * 0.13).normalized()
					fire_projectile("magic_wave", direction, roll_damage(), 22.0, 0.6, true)
				fire_projectile("nuke", forward, roll_damage() * 3.0, 18.0, 0.25, false, 8.0)

func melee_attack(reach: float) -> void:
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	var shape := SphereShape3D.new()
	shape.radius = reach
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, origin)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var struck: Array = []
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 64):
		var body: Node3D = hit["collider"]
		if not body.has_method("take_damage") or struck.has(body):
			continue
		var center: Vector3 = body.global_position + Vector3.UP
		if body.has_method("aim_point"):
			center = body.aim_point()
		var offset := center - origin
		if offset.length() > reach + 0.35 or forward.dot(offset.normalized()) < 0.35:
			continue
		var obstruction := ray(origin, center)
		if not obstruction.is_empty() and obstruction["collider"] == body:
			struck.append(body)
			deal_hit(body, roll_damage())

func roll_damage() -> float:
	var stats: Dictionary = run.stats()
	var damage: float = float(stats["attack"]) * float(WEAPONS[weapon_id]["damage"])
	if run.rng.randf() * 100.0 < float(stats["crit_chance"]):
		damage *= float(stats["crit_damage"]) / 100.0
	if weapon_id == "gun" and empowered > 0.0:
		damage *= 2.0
	return damage

func deal_hit(body: Object, damage: float, hit_weapon: String = "", grants_rpg: bool = false) -> void:
	if not is_instance_valid(body) or not body.has_method("take_damage"):
		return
	var monster_kill: bool = body.is_in_group("monsters")
	var death_position: Vector3 = body.global_position if body is Node3D else Vector3.ZERO
	var result: int = body.take_damage(damage)
	if result == 0:
		return
	if hit_weapon == "gun" and grants_rpg and run.weapon_level("gun") >= 4:
		rpg_ready = true
	combo.register_hit()
	feedback.text = "%d DAMAGE" % roundi(damage)
	feedback.modulate = Color(1.0, 0.85, 0.35)
	feedback_time = 0.55
	if result == 2:
		combo.register_kill()
		feedback.text = "TARGET DOWN"
		if monster_kill and weapon_id == "gun" and weapon_level() >= 3 and (hit_weapon.is_empty() or hit_weapon == "gun"):
			try_spawn_charge_target(death_position)
		run.add_xp(3)

func try_spawn_charge_target(death_position: Vector3) -> Node3D:
	if weapon_id != "gun" or weapon_level() < 3 or run.rng.randf() >= charge_target_chance:
		return null
	var target := StaticBody3D.new()
	target.set_script(CHARGE_TARGET)
	target.source = self
	get_tree().current_scene.add_child(target)
	target.global_position = death_position + Vector3(0, 3.0, 0)
	return target
func unlock_charge() -> void:
	charge_ready = true
	charge_time = 0.0
	attack_held = false
	feedback.text = "CHARGE READY"
	feedback.modulate = Color("ff6977")
	feedback_time = 1.0
	update_status()
func tracer(from: Vector3, to: Vector3) -> void:
	var line := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.012
	mesh.bottom_radius = 0.012
	mesh.height = maxf(from.distance_to(to), 0.01)
	line.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.8, 0.25)
	line.material_override = material
	get_tree().current_scene.add_child(line)
	line.global_position = (from + to) * 0.5
	line.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	get_tree().create_timer(0.06, false).timeout.connect(line.queue_free)

func spawn_target() -> void:
	if is_instance_valid(dummy):
		dummy.queue_free()
	dummy = TARGET.instantiate()
	get_tree().current_scene.add_child(dummy)
	var forward := -player.global_basis.z
	dummy.global_position = player.global_position + forward * 2.6
	dummy.global_position.y = 0.0



func weapon_level() -> int:
	return run.weapon_level(weapon_id) if run != null else 1

func attack_cooldown() -> float:
	var level := weapon_level()
	if weapon_id == "gun":
		return 0.07 if empowered > 0.0 else (0.12 if level >= 2 else 0.55)
	if weapon_id == "sword" and level >= 2:
		return 0.16 if level >= 5 else (0.25 if level >= 4 else 0.75)
	if weapon_id == "katana" and level >= 2:
		return 1.6 if level >= 5 else 1.0
	if weapon_id == "bow" and level >= 5:
		return 0.3
	if weapon_id == "spellbook" and level >= 3:
		return 3.0 if level >= 5 else 1.8
	return float(WEAPONS[weapon_id]["cooldown"])

func release_charge() -> void:
	if not can_act() or gun_reload > 0.0 or not charge_ready:
		charge_time = 0.0
		return
	if charge_time >= 0.45:
		charge_ready = false
		empowered = 2.0 + minf(charge_time, 1.5) * 2.0
		gun_reload = 0.0
		cooldown = 0.0
	charge_time = 0.0
	try_attack()

func update_status() -> void:
	if ability_status == null:
		return
	ammo_label.visible = weapon_id in ["gun", "bow"]
	ammo_hint.visible = ammo_label.visible
	var text := ""
	if weapon_id == "gun":
		ammo_label.text = "%02d / 12" % gun_ammo
		ammo_hint.text = "%s  RELOAD" % GameData.key_label("reload")
		if gun_reload > 0.0:
			ammo_hint.text = "RELOADING  %.1fs" % gun_reload
		elif charge_ready:
			ammo_hint.text += " | CHARGE READY"
		elif empowered > 0.0:
			ammo_label.text = "∞ / 12"
			ammo_hint.text = "POWER BURST  %.1fs" % empowered
		if weapon_level() >= 4:
			ammo_hint.text += "\nRMB  RPG " + ("READY" if rpg_ready else "NOT READY")
	elif weapon_id == "bow":
		ammo_label.text = "∞ / 4" if weapon_level() >= 5 else "%d / 4" % bow_ammo
		ammo_hint.text = "ARROWS" if bow_reload <= 0.0 else "RELOADING  %.1fs" % bow_reload
	elif weapon_id == "spellbook" and weapon_level() >= 4:
		text = "RMB: Warp | %.1fs cooldown" % special_cooldown
	elif weapon_id == "sword" and weapon_level() >= 4:
		text = "Hold LMB: rapid sword waves"
	ability_status.text = text
func fire_projectile(kind: String, direction: Vector3, damage: float, speed: float, radius: float, piercing: bool, splash: float = 0.0) -> Node3D:
	var shot := Node3D.new()
	shot.set_script(PROJECTILE)
	shot.direction = direction
	shot.speed = speed
	shot.damage = damage
	shot.kind = kind
	shot.source = self
	shot.hit_radius = radius
	shot.piercing = piercing
	shot.splash = splash
	shot.source_weapon = weapon_id
	shot.excluded.assign([player.get_rid()])
	get_tree().current_scene.add_child(shot)
	shot.global_position = camera.global_position + (-camera.global_basis.z) * 0.15
	shot.look_at(shot.global_position + direction, camera.global_basis.y)
	projectiles_fired += 1
	return shot

func aim_point(distance: float) -> Vector3:
	var origin := camera.global_position
	var end := origin - camera.global_basis.z * distance
	var hit := ray(origin, end)
	return end if hit.is_empty() else Vector3(hit["position"]) + Vector3(hit["normal"]) * 0.5

func tornado_round(count: int, damage: float) -> void:
	var center := aim_point(5.0)
	for i in range(count):
		var point := center + camera.global_basis.x * (float(i) - float(count - 1) * 0.5) * 1.8
		spawn_tornado(point, damage, 2.8, 1.1)

func spawn_tornado(point: Vector3, damage: float, radius: float, lifetime: float) -> Node3D:
	var tornado := Node3D.new()
	tornado.set_script(TORNADO)
	tornado.source = self
	tornado.damage = damage
	tornado.radius = radius
	tornado.remaining = lifetime
	get_tree().current_scene.add_child(tornado)
	tornado.global_position = point
	tornadoes_created += 1
	return tornado

func try_special() -> bool:
	if not can_act() or special_cooldown > 0.0:
		return false
	if weapon_id == "gun" and weapon_level() >= 4 and rpg_ready:
		rpg_ready = false
		special_cooldown = 1.0
		fire_projectile("rpg", -camera.global_basis.z, roll_damage() * 3.0, 28.0, 0.15, false, 4.0)
		return true
	if weapon_id == "spellbook" and weapon_level() >= 4:
		return warp()
	return false

func warp() -> bool:
	# Sweep the player capsule to avoid teleporting through walls.
	var motion := -player.global_basis.z * 8.0
	var body_query := PhysicsTestMotionParameters3D.new()
	body_query.from = player.global_transform
	body_query.motion = motion
	var result := PhysicsTestMotionResult3D.new()
	if PhysicsServer3D.body_test_motion(player.get_rid(), body_query, result):
		motion *= maxf(0.0, result.get_collision_safe_fraction() - 0.02)
	if motion.length() < 0.5:
		return false
	var destination := player.global_position + motion
	var floor_hit := ray(destination + Vector3.UP * 2.0, destination - Vector3.UP * 3.0)
	if floor_hit.is_empty() or floor_hit["normal"].y < 0.8:
		return false
	var old_position := player.global_position
	player.global_position += motion
	player.velocity = Vector3.ZERO
	special_cooldown = 3.0
	flash(old_position + Vector3.UP, 1.0, Color(0.3, 0.5, 1))
	flash(player.global_position + Vector3.UP, 1.0, Color(0.3, 0.5, 1))
	return true

func damageables(center: Vector3, radius: float) -> Array:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var result: Array = []
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 128):
		var body: Node3D = hit["collider"]
		if body.has_method("take_damage") and not result.has(body):
			var target: Vector3 = body.aim_point() if body.has_method("aim_point") else body.global_position + Vector3.UP
			var obstruction := ray(center, target)
			if obstruction.is_empty() or obstruction["collider"] == body:
				result.append(body)
	return result

func explode(center: Vector3, radius: float, damage: float, ignored: Object = null) -> void:
	flash(center, radius, Color(1.0, 0.45, 0.1))
	for body in damageables(center, radius):
		if body != ignored:
			deal_hit(body, damage)

func flash(center: Vector3, radius: float, color: Color) -> void:
	var effect := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	effect.mesh = sphere
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, 0.25)
	effect.material_override = material
	get_tree().current_scene.add_child(effect)
	effect.global_position = center
	effect.scale = Vector3.ONE * 0.15
	var tween := effect.create_tween()
	tween.tween_property(effect, "scale", Vector3.ONE, 0.15)
	tween.tween_property(effect, "scale", Vector3.ONE * 0.01, 0.15)
	tween.tween_callback(effect.queue_free)
