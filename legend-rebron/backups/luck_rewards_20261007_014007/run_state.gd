extends Node
signal changed
signal player_died
var finished := false
var elapsed_time := 0.0
var monsters_killed := 0
var regen_elapsed := 0.0
signal offers_changed
const Catalog = preload("res://scripts/item_catalog.gd")
var catalog = Catalog.new()
var rng := RandomNumberGenerator.new()
var level: int = 1
var xp: int = 0
var owned_ids: Array[String] = []
var item_counts: Dictionary = {}
var offer_generation: int = 0
var offers: Array[String] = []
var reward_level: int = 0
var pending_levels: Array[int] = []
var character_name: String = ""
var equipped_weapon_id: String = ""
func _init() -> void:
	rng.randomize()
func xp_to_next() -> int:
	var config: Dictionary = catalog.data["progression"]
	return int(config["xp_initial"]) + (level - 1) * int(config["xp_per_level"])
func stats() -> Dictionary:
	var result: Dictionary = catalog.data["base_stats"].duplicate()
	for id in owned_ids:
		var effects: Dictionary = catalog.item_for(id)["effects"]
		for stat in effects:
			result[stat] += effects[stat] * stack_count(id)
	return result
func stack_count(id: String) -> int:
	return int(item_counts.get(id, 0))
func total_items() -> int:
	var total := 0
	for count in item_counts.values():
		total += int(count)
	return total
func rarity_weights(at_level: int) -> Dictionary:
	var config: Dictionary = catalog.data["progression"]
	var progress := clampf(float(at_level - int(config["rarity_level_start"])) / float(config["rarity_level_end"] - config["rarity_level_start"]), 0.0, 1.0)
	var weights: Dictionary = {}
	for rarity in config["early_weights"]:
		weights[rarity] = lerpf(float(config["early_weights"][rarity]), float(config["late_weights"][rarity]), progress)
		if at_level < int(config.get("rarity_min_levels", {}).get(rarity, 1)):
			weights[rarity] = 0.0
	return weights
func roll_choices(at_level: int) -> Array[String]:
	var weights := rarity_weights(at_level)
	var available: Array = []
	for item in catalog.items:
		if float(weights.get(item["rarity"], 0.0)) > 0.0:
			available.append(item)
	var result: Array[String] = []
	while result.size() < 3 and not available.is_empty():
		var groups: Dictionary = {}
		for item in available:
			var rarity: String = item["rarity"]
			if not groups.has(rarity):
				groups[rarity] = []
			groups[rarity].append(item)
		var total := 0.0
		for rarity in groups:
			total += float(weights[rarity])
		var draw := rng.randf() * total
		var chosen_rarity: String = groups.keys()[-1]
		for rarity in groups:
			draw -= float(weights[rarity])
			if draw <= 0.0:
				chosen_rarity = rarity
				break
		var group: Array = groups[chosen_rarity]
		var selected: Dictionary = group[rng.randi_range(0, group.size() - 1)]
		result.append(selected["id"])
		available.erase(selected)
	return result
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		pending_levels.append(level)
		if level % WEAPON_UPGRADE_INTERVAL == 0:
			upgrade_weapon()
	changed.emit()
	if offers.is_empty():
		_next_reward()
func test_level_up() -> void:
	if offers.is_empty():
		add_xp(xp_to_next() - xp)
func _next_reward() -> void:
	offer_generation += 1
	offers.clear()
	while not pending_levels.is_empty():
		reward_level = pending_levels.pop_front()
		offers = roll_choices(reward_level)
		if not offers.is_empty():
			break
	offers_changed.emit()
func choose_item(id: String, generation: int = -1) -> bool:
	if (generation >= 0 and generation != offer_generation) or not offers.has(id):
		return false
	if not owned_ids.has(id):
		owned_ids.append(id)
	item_counts[id] = stack_count(id) + 1
	offers.clear()
	changed.emit()
	_next_reward()
	return true

func weapon_name() -> String:
	for weapon in catalog.data["weapons"]:
		if weapon["id"] == equipped_weapon_id:
			return str(weapon["name"])
	return catalog.weapon_name(character_name)

# Store damage taken so Max HP upgrades preserve missing health.
var damage_taken := 0.0
func current_health() -> float:
	return maxf(0.0, float(stats()["max_hp"]) - damage_taken)
func damage_player(amount: float) -> bool:
	if finished:
		return current_health() <= 0.0
	damage_taken += maxf(0.0, amount)
	var dead := current_health() <= 0.0
	if dead:
		finished = true
	changed.emit()
	if dead:
		player_died.emit()
	return dead
func restore_health() -> void:
	damage_taken = 0.0
	changed.emit()

const MAX_WEAPON_LEVEL := 5
const WEAPON_UPGRADE_INTERVAL := 10
var weapon_levels: Dictionary = {}
func weapon_level(id: String = "") -> int:
	var selected := equipped_weapon_id if id.is_empty() else id
	return int(weapon_levels.get(selected, 1))
func upgrade_weapon() -> bool:
	if equipped_weapon_id.is_empty():
		return false
	var valid := false
	for weapon in catalog.data["weapons"]:
		if weapon["id"] == equipped_weapon_id:
			valid = true
			break
	if not valid or weapon_level() >= MAX_WEAPON_LEVEL:
		return false
	weapon_levels[equipped_weapon_id] = weapon_level() + 1
	changed.emit()
	return true

func weapon_ability() -> String:
	return preload("res://scripts/weapon_progression.gd").description(equipped_weapon_id, weapon_level())

func _physics_process(delta: float) -> void:
	if finished or get_tree().paused:
		return
	elapsed_time += delta
	regen_elapsed += delta
	var ticks := int(floorf(regen_elapsed))
	if ticks <= 0:
		return
	regen_elapsed -= float(ticks)
	if current_health() > 0.0 and damage_taken > 0.0:
		damage_taken = maxf(0.0, damage_taken - float(ticks))
		changed.emit()

func record_monster_kill() -> void:
	if finished:
		return
	monsters_killed += 1
	changed.emit()

func result_summary() -> Dictionary:
	var inventory: Array[Dictionary] = []
	for id in owned_ids:
		var item: Dictionary = catalog.item_for(id)
		inventory.append({"name": item["name"], "count": stack_count(id), "color": catalog.rarity_color(item["rarity"])})
	return {
		"elapsed_seconds": elapsed_time,
		"monsters_killed": monsters_killed,
		"character": character_name,
		"level": level,
		"weapon_name": weapon_name(),
		"weapon_level": weapon_level(),
		"items": inventory,
		"item_total": total_items(),
		"stats": stats().duplicate(true),
		"health": current_health()
	}

