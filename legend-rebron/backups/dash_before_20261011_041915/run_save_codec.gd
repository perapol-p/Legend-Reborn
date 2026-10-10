extends RefCounted
const RUN_FIELDS = ["level","xp","character_name","equipped_weapon_id","elapsed_time","regen_elapsed","monsters_killed","damage_taken","owned_ids","item_counts","weapon_levels","offer_generation","offers_without_high_rarity","offers","reward_level","pending_levels"]
const COMBAT_FIELDS = ["cooldown","pending","elapsed","attack_active","charge_ready","charge_time","empowered","gun_ammo","gun_reload","bow_ammo","bow_reload","known_bow_capacity","rpg_ready","special_cooldown","volley_queue","attack_serial","projectiles_fired","tornadoes_created"]
const SPAWN_FIELDS = ["enabled","survival_time","difficulty_step","countdown","started","total_spawned","last_distance","boss_phase","boss_started"]
const ACTOR_FIELDS = ["health","max_health","alive_seconds","pressure_multiplier","base_move_speed","base_attack_damage","base_attack_interval","attack_timer","hit_flash","velocity"]
const SHOT_FIELDS = ["kind","direction","speed","damage","source_weapon","remaining","hit_radius","piercing","critical","splash","velocity","flight_time","travel_remaining"]
const ENEMY_SHOT_FIELDS = ["kind","velocity","damage","source_position","gravity","remaining","max_distance","distance_travelled"]
static func fields(node: Object, keys: Array) -> Dictionary:
	var values: Dictionary = {}
	for key in keys:
		values[key] = node.get(key)
	return values.duplicate(true)
static func apply(node: Object, values: Dictionary, keys: Array) -> void:
	for key in keys:
		if values.has(key):
			node.set(key,values[key])
static func actor_kind(actor: Node) -> String:
	if actor.is_in_group("bosses"):
		return "boss"
	if actor.is_in_group("archer_monsters"):
		return "archer"
	if actor.is_in_group("flying_monsters"):
		return "flyer"
	return "melee"
static func indices_for_rids(rids: Array, actors: Array) -> Array:
	var indices: Array = []
	for i in actors.size():
		if rids.has(actors[i].get_rid()):
			indices.append(i)
	return indices
static func rids_for_indices(indices: Array, actors: Array) -> Array[RID]:
	var rids: Array[RID] = []
	for value in indices:
		var i := int(value)
		if i >= 0 and i < actors.size():
			rids.append(actors[i].get_rid())
	return rids
static func capture(game: Node3D) -> Dictionary:
	var run = game.get_node("RunState")
	var player = game.get_node("Player")
	var combat = player.get_node("Head/Camera3D/Combat")
	var spawner = game.get_node("MonsterSpawner")
	var data := {"version":1,"stage":game.stage_id,"run":fields(run,RUN_FIELDS),"combat":fields(combat,COMBAT_FIELDS),"spawner":fields(spawner,SPAWN_FIELDS),"combo":fields(game.get_node("Combo"),["points","remaining"])}
	data["run"]["rng_seed"] = run.rng.seed
	data["run"]["rng_state"] = run.rng.state
	data["spawner"]["rng_seed"] = spawner.rng.seed
	data["spawner"]["rng_state"] = spawner.rng.state
	data["player"] = {"transform":player.global_transform,"head_rotation":player.head.rotation,"head_position":player.head.position,"velocity":player.velocity,"dash_remaining":player.dash_remaining,"dash_recovery":player.dash_recovery,"dash_direction":player.dash_direction,"camera_side_offset":player.camera_side_offset}
	data["music_position"] = game.music.get_playback_position()
	var animation = combat.view.get_node_or_null("Model/AnimationPlayer")
	if animation is AnimationPlayer:
		data["animation"] = {"name":animation.current_animation,"position":animation.current_animation_position,"speed":animation.speed_scale,"attacking":combat.view.attacking}
	if combat.weapon_id == "bow":
		data["arrow_released"] = combat.view.arrow_released
	var actors: Array = []
	var saved_actors: Array = []
	for actor in spawner.monsters:
		if not is_instance_valid(actor) or actor.dead or actor.is_queued_for_deletion():
			continue
		actors.append(actor)
		var saved := fields(actor,ACTOR_FIELDS)
		saved["kind"] = actor_kind(actor)
		saved["transform"] = actor.global_transform
		if saved["kind"] in ["archer","flyer"]:
			saved.merge(fields(actor,["windup_remaining","locked_target","hover_time","shots_fired"]))
		saved_actors.append(saved)
	data["actors"] = saved_actors
	var volleys: Array = []
	var saved_volleys: Array = []
	var shots: Array = []
	for shot in game.get_tree().get_nodes_in_group("weapon_projectiles"):
		if shot.source != combat or shot.is_queued_for_deletion():
			continue
		var saved := fields(shot,SHOT_FIELDS)
		saved["transform"] = shot.global_transform
		saved["struck"] = indices_for_rids(shot.struck,actors)
		if shot.kind == "bow":
			var volley_index := -1
			for i in volleys.size():
				if is_same(volleys[i],shot.bow_volley_hits):
					volley_index = i
					break
			if volley_index < 0:
				volley_index = volleys.size()
				volleys.append(shot.bow_volley_hits)
				saved_volleys.append(indices_for_rids(shot.bow_volley_hits.keys(),actors))
			saved["volley"] = volley_index
		shots.append(saved)
	data["shots"] = shots
	data["volleys"] = saved_volleys
	var enemy_shots: Array = []
	for shot in game.get_tree().get_nodes_in_group("enemy_projectiles"):
		if shot.player != player or shot.is_queued_for_deletion():
			continue
		var saved := fields(shot,ENEMY_SHOT_FIELDS)
		saved["transform"] = shot.global_transform
		saved["excluded"] = indices_for_rids(shot.excluded,actors)
		enemy_shots.append(saved)
	data["enemy_shots"] = enemy_shots
	var tornadoes: Array = []
	for tornado in game.get_tree().get_nodes_in_group("weapon_tornadoes"):
		if tornado.source == combat and not tornado.is_queued_for_deletion():
			var saved := fields(tornado,["damage","critical","source_weapon","radius","remaining","pulse"])
			saved["transform"] = tornado.global_transform
			saved["spin"] = tornado.model.rotation.y
			tornadoes.append(saved)
	data["tornadoes"] = tornadoes
	var targets: Array = []
	for target in game.get_tree().get_nodes_in_group("gun_charge_targets"):
		if target.source == combat and not target.collected and not target.is_queued_for_deletion():
			targets.append({"transform":target.global_transform,"remaining":target.remaining})
	data["charge_targets"] = targets
	return data
static func restore_run(game: Node, data: Dictionary) -> void:
	var run = game.get_node("RunState")
	apply(run,data["run"],RUN_FIELDS)
	run.finished = false
	run.rng.seed = int(data["run"]["rng_seed"])
	run.rng.state = int(data["run"]["rng_state"])
static func restore_world(game: Node3D, data: Dictionary) -> void:
	var run = game.get_node("RunState")
	var player = game.get_node("Player")
	var combat = player.get_node("Head/Camera3D/Combat")
	var spawner = game.get_node("MonsterSpawner")
	combat.equip(data["run"]["equipped_weapon_id"])
	apply(combat,data["combat"],COMBAT_FIELDS)
	combat.attack_held = false
	var pose: Dictionary = data["player"]
	player.global_transform = pose["transform"]
	player.head.rotation = pose["head_rotation"]
	player.head.position = pose["head_position"]
	apply(player,pose,["velocity","dash_remaining","dash_recovery","dash_direction","camera_side_offset"])
	var actors: Array = []
	var paths := {"melee":"monster","archer":"archer_monster","flyer":"flying_monster","boss":"boss"}
	spawner.monsters.clear()
	for saved in data.get("actors",[]):
		var actor = load("res://scenes/" + paths[saved["kind"]] + ".tscn").instantiate()
		actor.player = player
		actor.max_health = saved["max_health"]
		actor.move_speed = saved["base_move_speed"]
		actor.attack_damage = saved["base_attack_damage"]
		actor.attack_interval = saved["base_attack_interval"]
		actor.transform = spawner.global_transform.affine_inverse() * saved["transform"]
		spawner.add_child(actor)
		apply(actor,saved,ACTOR_FIELDS)
		actor.advance_age(0.0)
		if saved["kind"] in ["archer","flyer"]:
			apply(actor,saved,["windup_remaining","locked_target","hover_time","shots_fired"])
			actor.charge_visual.visible = actor.windup_remaining >= 0.0
		actor.refresh()
		spawner.monsters.append(actor)
		actors.append(actor)
		if saved["kind"] == "boss":
			spawner.boss = actor
			actor.defeated.connect(spawner._on_boss_defeated)
	apply(spawner,data["spawner"],SPAWN_FIELDS)
	spawner.completed = false
	spawner.rng.seed = int(data["spawner"]["rng_seed"])
	spawner.rng.state = int(data["spawner"]["rng_state"])
	var volleys: Array[Dictionary] = []
	for indices in data.get("volleys",[]):
		var hits: Dictionary = {}
		for rid in rids_for_indices(indices,actors):
			hits[rid] = true
		volleys.append(hits)
	for saved in data.get("shots",[]):
		var shot = preload("res://scripts/weapon_projectile.gd").new()
		apply(shot,saved,SHOT_FIELDS)
		shot.source = combat
		shot.excluded.assign([player.get_rid()])
		shot.struck = rids_for_indices(saved.get("struck",[]),actors)
		if saved.has("volley"):
			shot.bow_volley_hits = volleys[int(saved["volley"])]
		shot.transform = game.global_transform.affine_inverse() * saved["transform"]
		game.add_child(shot)
		apply(shot,saved,SHOT_FIELDS)
	for saved in data.get("enemy_shots",[]):
		var shot = preload("res://scripts/enemy_projectile.gd").new()
		apply(shot,saved,ENEMY_SHOT_FIELDS)
		shot.player = player
		shot.excluded = rids_for_indices(saved.get("excluded",[]),actors)
		shot.transform = game.global_transform.affine_inverse() * saved["transform"]
		game.add_child(shot)
	for saved in data.get("tornadoes",[]):
		var tornado = preload("res://scripts/weapon_tornado.gd").new()
		apply(tornado,saved,["damage","critical","source_weapon","radius","remaining","pulse"])
		tornado.source = combat
		tornado.transform = game.global_transform.affine_inverse() * saved["transform"]
		game.add_child(tornado)
		tornado.model.rotation.y = saved["spin"]
	for saved in data.get("charge_targets",[]):
		var target = preload("res://scripts/gun_charge_target.gd").new()
		target.source = combat
		target.remaining = saved["remaining"]
		target.transform = game.global_transform.affine_inverse() * saved["transform"]
		game.add_child(target)
	var animation = combat.view.get_node_or_null("Model/AnimationPlayer")
	if animation is AnimationPlayer and data.has("animation"):
		var saved: Dictionary = data["animation"]
		if animation.has_animation(saved["name"]):
			animation.play(saved["name"],0.0)
			animation.speed_scale = saved["speed"]
			animation.seek(saved["position"],true)
			combat.view.attacking = saved["attacking"]
	if combat.weapon_id == "bow":
		combat.view.arrow_released = data.get("arrow_released",false)
	apply(game.get_node("Combo"),data["combo"],["points","remaining"])
	game.get_node("Combo").changed.emit()
	run.changed.emit()
	game.music.seek(float(data.get("music_position",0.0)))
	game._sync_reward()
