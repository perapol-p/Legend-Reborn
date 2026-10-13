extends RefCounted
# Matches Screenshot 2026-09-28 003817.png. Timing/damage are prototype tuning.
const ABILITIES = {
	"sword": ["Wide melee slash", "Piercing sword wave; short range (6 m)", "Larger piercing sword wave; medium range (12 m)", "Rapid piercing sword waves; long range (20 m)", "Faster piercing sword waves; very long range (32 m)"],
	"bow": ["1 arrow; 4 shots per reload", "3 arrows; 6 shots per reload", "6 piercing arrows; 8 shots per reload", "6 upper + 6 lower piercing arrows; 10 shots per reload", "12 piercing arrows, unlimited ammo"],
	"spellbook": ["Magic wave", "Larger magic wave", "1 magic fireball; 25% tornado chance", "Faster fireballs; 50% tornado chance; RMB: warp", "Fastest fireballs; 100% tornado chance; RMB: warp"]
}
static func description(id: String, level: int) -> String:
	if not ABILITIES.has(id):
		return ""
	return str(ABILITIES[id][clampi(level, 1, 5) - 1]) + " / Hold LMB to attack"




