extends SceneTree
const Run = preload("res://scripts/run_state.gd")
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _initialize() -> void:
	for weapon in ["sword", "bow", "spellbook"]:
		var run = Run.new()
		run.equipped_weapon_id = weapon
		for target in range(2, 43):
			run.add_xp(run.xp_to_next()-run.xp)
			check(run.reward_phase == "item" and run.weapon_level() == target-1, "Item must come first")
			var generation: int = run.offer_generation
			var item: String = run.offers[0]
			check(run.choose_item(item, generation), "Accept item")
			check(run.reward_phase == "weapon" and run.weapon_level() == target and run.offers.size() == 3, "Every level offers three upgrades without cap")
			check(not run.choose_item(item,generation), "Reject duplicate item")
			var choice: String = run.offers[(target-2)%3]
			check(not run.choose_weapon_upgrade(choice,generation), "Reject stale upgrade input")
			check(run.choose_weapon_upgrade(choice,run.offer_generation), "Accept selected upgrade")
			check(run.offers.is_empty(), "Complete one reward pair")
			check(not run.choose_weapon_upgrade(choice), "No duplicate upgrades")
		check(run.upgrade_count(weapon,run.Progression.UPGRADES[weapon][0]) == 14, "Repeat choices stack")
		run.free()
	var bulk = Run.new()
	bulk.equipped_weapon_id = "bow"
	bulk.add_xp(45)
	check(bulk.level == 4 and bulk.pending_levels.size() == 2, "Multiple levels queued")
	for i in range(3):
		check(bulk.choose_item(bulk.offers[0]), "Queued item")
		check(bulk.choose_weapon_upgrade("projectile_count"), "Queued upgrade")
	check(bulk.weapon_level() == 4 and bulk.upgrade_count("bow","projectile_count") == 3 and bulk.offers.is_empty(), "Each queued level grants exactly one choice")
	bulk.free()
	print("CHARACTER WEAPON PROGRESSION ", "FAILED" if failed else "PASSED")
	quit(1 if failed else 0)
