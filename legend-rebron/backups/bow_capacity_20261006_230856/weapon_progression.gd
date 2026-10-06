extends RefCounted
# Matches Screenshot 2026-09-28 003817.png. Timing/damage are prototype tuning.
const ABILITIES = {
	"sword": ["Wide melee slash", "Slow sword wave", "Larger sword wave", "Rapid sword waves (hold LMB)", "Faster rapid sword waves (hold LMB)"],
	"katana": ["Slash + dash", "Tornado pulls monsters together", "Dash distance +50%", "2 tornadoes x 2 rounds", "3 tornadoes x 5 rounds"],
	"gun": ["Slow fire", "Fast fire", "Kills may spawn a red target. Shoot within 3s to unlock one charged burst", "Hit a target to earn 1 RPG; RMB launches it", "Explosive bullets + red-target charge + RPG"],
	"bow": ["2 arrows", "4 arrows", "8 piercing arrows", "8 upper + 8 lower piercing arrows", "24 piercing arrows, no reload (hold LMB)"],
	"spellbook": ["Magic wave", "Larger magic wave", "Tornado spell", "RMB: warp (tornado on LMB)", "Nuke + multiple spells together; RMB: warp"]
}
static func description(id: String, level: int) -> String:
	if not ABILITIES.has(id):
		return ""
	return str(ABILITIES[id][clampi(level, 1, 5) - 1])

