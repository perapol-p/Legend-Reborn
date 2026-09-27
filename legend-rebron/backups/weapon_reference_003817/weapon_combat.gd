extends Node3D
## Gameplay lives here; replace only the Models in scenes/weapons to swap art.
const PROJECTILE = preload("res://scripts/weapon_projectile.gd")
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

func bind_combat(body: CharacterBody3D, model: Node, meter: Node) -> void:
	player = body
	camera = get_parent() as Camera3D
	run = model
	combo = meter
	var layer := CanvasLayer.new()
	add_child(layer)
	var hint := Label.new()
	hint.text = "LMB Attack  |  1 Sword  2 Katana  3 Gun  4 Bow  5 Spellbook  |  T Target"
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hint.position = Vector2(-360, 8)
	hint.size.x = 720
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(hint)
	feedback = Label.new()
	layer.add_child(feedback)
	feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	feedback.position = Vector2(-120, 28)
	feedback.size.x = 240
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback.add_theme_constant_override("shadow_offset_y", 2)
	equip(str(run.catalog.data["character_weapons"].get(run.character_name, "sword")))

func can_act() -> bool:
	return is_instance_valid(player) and player.input_enabled and not get_tree().paused and not GameData.rebinding_active

func equip(id: String) -> void:
	if not WEAPONS.has(id):
		return
	pending = -1.0
	attack_active = false
	weapon_id = id
	if is_instance_valid(view):
		remove_child(view)
		view.queue_free()
	view = load("res://scenes/weapons/" + id + ".tscn").instantiate()
	add_child(view)
	run.equipped_weapon_id = id
	run.changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not can_act() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_attack()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key >= KEY_1 and key <= KEY_5:
			equip(ORDER[key - KEY_1])
			get_viewport().set_input_as_handled()
		elif key == KEY_T:
			spawn_target()
			get_viewport().set_input_as_handled()

func try_attack() -> bool:
	if not can_act() or cooldown > 0.0:
		return false
	cooldown = float(WEAPONS[weapon_id]["cooldown"])
	pending = float(WEAPONS[weapon_id]["delay"])
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
	feedback_time = maxf(0.0, feedback_time - delta)
	feedback.visible = feedback_time > 0.0
	if not can_act():
		pending = -1.0
		attack_active = false
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
		var t := clampf(elapsed / float(WEAPONS[weapon_id]["cooldown"]), 0, 1)
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

func ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func resolve_attack() -> void:
	if not can_act():
		return
	var config: Dictionary = WEAPONS[weapon_id]
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	if weapon_id in ["sword", "katana"]:
		var reach := float(config["reach"])
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
			if offset.length() > reach + 0.35 or forward.dot(offset.normalized()) < 0.55:
				continue
			var obstruction := ray(origin, center)
			if not obstruction.is_empty() and obstruction["collider"] == body:
				struck.append(body)
				deal_hit(body, roll_damage())
	elif weapon_id == "gun":
		var hit := ray(origin, origin + forward * float(config["reach"]))
		var end: Vector3 = origin + forward * float(config["reach"]) if hit.is_empty() else hit["position"]
		tracer(origin + camera.global_basis * Vector3(0.26, -0.18, -0.6), end)
		if not hit.is_empty():
			deal_hit(hit["collider"], roll_damage())
	else:
		var shot := Node3D.new()
		shot.set_script(PROJECTILE)
		shot.direction = forward
		shot.speed = float(config["speed"])
		shot.damage = roll_damage()
		shot.kind = weapon_id
		shot.source = self
		shot.excluded.assign([player.get_rid()])
		get_tree().current_scene.add_child(shot)
		shot.global_position = origin + forward * 0.15
		shot.look_at(shot.global_position + forward, camera.global_basis.y)

func roll_damage() -> float:
	var stats: Dictionary = run.stats()
	var damage: float = float(stats["attack"]) * float(WEAPONS[weapon_id]["damage"]) * run.weapon_damage_multiplier(weapon_id)
	if run.rng.randf() * 100.0 < float(stats["crit_chance"]):
		damage *= float(stats["crit_damage"]) / 100.0
	return damage

func deal_hit(body: Object, damage: float) -> void:
	if not is_instance_valid(body) or not body.has_method("take_damage"):
		return
	var result: int = body.take_damage(damage)
	if result == 0:
		return
	combo.register_hit()
	feedback.text = "%d DAMAGE" % roundi(damage)
	feedback.modulate = Color(1.0, 0.85, 0.35)
	feedback_time = 0.55
	if result == 2:
		combo.register_kill()
		feedback.text = "TARGET DOWN"
		run.add_xp(3)

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

