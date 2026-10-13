extends RefCounted
const UPGRADES = {
	"sword": ["attack_speed", "wave_size", "wave_range_speed"],
	"bow": ["attack_speed", "projectile_count", "pierce_count"],
	"spellbook": ["cast_speed", "storm_cooldown", "explosion_size"]
}
const OPTIONS = {
	"attack_speed": {"name": "Attack Speed", "description": "+10% attack speed per upgrade"},
	"wave_size": {"name": "Sword Wave Size", "description": "+15% sword wave size per upgrade"},
	"wave_range_speed": {"name": "Sword Wave Range + Speed", "description": "+15% wave range and travel speed per upgrade"},
	"projectile_count": {"name": "Projectile Count", "description": "+1 arrow per shot"},
	"pierce_count": {"name": "Pierce Count", "description": "Arrows pass through +1 enemy"},
	"cast_speed": {"name": "Cast Speed", "description": "+10% normal casting speed per upgrade"},
	"storm_cooldown": {"name": "Storm Cooldown", "description": "Reduce storm cooldown; +1 storm per spawn every 5 upgrades"},
	"explosion_size": {"name": "Explosion Size", "description": "+15% explosion radius per upgrade"}
}
static func description(id: String, _level: int) -> String:
	return {"sword": "Piercing sword waves / Hold LMB", "bow": "Arrow volleys / Hold LMB", "spellbook": "Fireballs / Automatic storm / RMB: Warp / E: Explosion"}.get(id, "")

# Authoritative combat balance. UI reads these same calculated values.
const BASE = {
	"sword": {"attack_interval": 0.55, "wave_size": 1.25, "wave_hit_radius": 0.4, "wave_range": 6.0, "wave_speed": 14.0},
	"bow": {"attack_interval": 0.8, "arrow_count": 1, "pierce_count": 0},
	"spellbook": {"attack_interval": 0.65, "explosion_size": 27.0}
}
const SPEED_PER_RANK := 0.10
const SIZE_PER_RANK := 0.15
const STORM = {
	"spawn_radius": 10.0, "base_cooldown": 8.0, "cooldown_factor": 1.10, "minimum_cooldown": 0.5,
	"base_spawn_count": 1, "upgrades_per_extra_storm": 5, "duration": 2.5, "damage_radius": 3.5, "damage_multiplier": 0.45, "visual_rotation_speed": 0.2
}
static func stats(run: Node, id: String) -> Dictionary:
	if not BASE.has(id): return {}
	var result: Dictionary = BASE[id].duplicate()
	result["level"] = run.weapon_level(id)
	var speed_key := "cast_speed" if id == "spellbook" else "attack_speed"
	var speed_rank: int = run.upgrade_count(id, speed_key)
	result["speed_level"] = speed_rank + 1
	result["attack_interval"] /= 1.0 + SPEED_PER_RANK * speed_rank
	result["attack_speed"] = 1.0 / float(result["attack_interval"])
	if id == "sword":
		var size_factor: float = 1.0 + SIZE_PER_RANK * run.upgrade_count(id,"wave_size")
		var range_factor: float = 1.0 + SIZE_PER_RANK * run.upgrade_count(id,"wave_range_speed")
		result["wave_size"] *= size_factor
		result["wave_hit_radius"] *= size_factor
		result["wave_range"] *= range_factor
		result["wave_speed"] *= range_factor
	elif id == "bow":
		result["arrow_count"] += run.upgrade_count(id,"projectile_count")
		result["pierce_count"] += run.upgrade_count(id,"pierce_count")
	else:
		var storm_rank: int = run.upgrade_count(id,"storm_cooldown")
		result["cast_speed"] = result["attack_speed"]
		result["cast_speed_level"] = speed_rank + 1
		result["storm_level"] = storm_rank + 1
		result["storm_cooldown"] = maxf(float(STORM["minimum_cooldown"]), float(STORM["base_cooldown"]) / pow(float(STORM["cooldown_factor"]), storm_rank))
		result["storm_spawn_radius"] = STORM["spawn_radius"]
		result["storm_spawn_count"] = int(STORM["base_spawn_count"]) + floori(float(storm_rank) / float(STORM["upgrades_per_extra_storm"]))
		result["explosion_size_level"] = run.upgrade_count(id,"explosion_size") + 1
		result["explosion_size"] *= 1.0 + SIZE_PER_RANK * run.upgrade_count(id,"explosion_size")
	return result

static func display_name(id: String) -> String:
	return {"sword":"Sword", "bow":"Bow", "spellbook":"Staff"}.get(id, id.capitalize())

static func stat_text(values: Dictionary, id: String) -> String:
	if values.is_empty(): return ""
	if id == "sword":
		return "Attack Speed : %.2f /sec\nWave Size : %.2f m\nWave Range : %.2f m\nWave Speed : %.2f m/s" % [values["attack_speed"], values["wave_size"], values["wave_range"], values["wave_speed"]]
	if id == "bow":
		return "Attack Speed : %.2f /sec\nArrow Per Shot : %d\nPierce Per Shot : %d" % [values["attack_speed"], values["arrow_count"], values["pierce_count"]]
	return "Cast Speed : %.2f /sec\nStorm : Lv.%d\n  Cooldown : %.2f s\n  Per Spawn : %d\n  Spawn Radius : %.2f m\nExplosion Size : %.2f m" % [values["cast_speed"], values["storm_level"], values["storm_cooldown"], values["storm_spawn_count"], values["storm_spawn_radius"], values["explosion_size"]]

