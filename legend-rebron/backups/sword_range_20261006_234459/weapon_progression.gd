extends RefCounted
# Matches Screenshot 2026-09-28 003817.png. Timing/damage are prototype tuning.
const ABILITIES = {
	"sword": ["Wide melee slash", "Sword wave, stops on hit", "Larger sword wave, stops on hit", "Rapid sword waves, stops on hit (hold LMB)", "Faster piercing sword waves (hold LMB)"],
	"katana": ["Slash + dash", "Tornado pulls monsters together", "Dash distance +50%", "2 tornadoes x 2 rounds", "3 tornadoes x 5 rounds"],
	"gun": ["Slow fire", "Fast fire", "Kills may spawn a red target. Shoot within 3s to unlock one charged burst", "Hit a target to earn 1 RPG; RMB launches it", "Explosive bullets + red-target charge + RPG"],
	"bow": ["1 arrow; 4 shots per reload", "3 arrows; 6 shots per reload", "6 piercing arrows; 8 shots per reload", "6 upper + 6 lower piercing arrows; 10 shots per reload", "12 piercing arrows, unlimited ammo (hold LMB)"],
	"spellbook": ["Magic wave", "Larger magic wave", "Tornado spell", "RMB: warp (tornado on LMB)", "Nuke + multiple spells together; RMB: warp"]
}
static func description(id: String, level: int) -> String:
	if not ABILITIES.has(id):
		return ""
	return str(ABILITIES[id][clampi(level, 1, 5) - 1])



