extends SceneTree
const Run = preload("res://scripts/run_state.gd")
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func advance_to(run: Node, target: int) -> void:
	while run.level < target:
		run.add_xp(run.xp_to_next() - run.xp)
func _initialize() -> void:
	var run = Run.new()
	run.equipped_weapon_id = "sword"
	advance_to(run, 9)
	check(run.weapon_level() == 1, "No weapon upgrade before level 10")
	advance_to(run, 10)
	check(run.weapon_level() == 2, "Level 10 upgrades weapon once")
	run.add_xp(1)
	check(run.weapon_level() == 2, "XP without level-up cannot duplicate upgrade")
	advance_to(run, 19)
	check(run.weapon_level() == 2, "Levels 11-19 do not upgrade")
	advance_to(run, 20)
	check(run.weapon_level() == 3, "Level 20 upgrades weapon")
	advance_to(run, 29)
	run.equipped_weapon_id = "gun"
	advance_to(run, 30)
	check(run.weapon_level("gun") == 2 and run.weapon_level("sword") == 3, "Only equipped weapon upgrades; previous weapon retains level")
	check(run.offers.size() == 3 and run.pending_levels.size() == 28, "Normal item rewards stay queued for every character level")
	run.free()
	var bulk = Run.new()
	bulk.equipped_weapon_id = "bow"
	var total_xp := 0
	for level in range(1, 40):
		bulk.level = level
		total_xp += bulk.xp_to_next()
	bulk.level = 1
	bulk.add_xp(total_xp)
	check(bulk.level == 40 and bulk.weapon_level() == 5, "One XP award crossing four milestones upgrades four times")
	advance_to(bulk, 60)
	check(bulk.weapon_level() == 5, "Weapon level stays capped at five")
	bulk.free()
	var empty = Run.new()
	advance_to(empty, 10)
	check(empty.weapon_levels.is_empty(), "No invalid weapon upgraded without equipped weapon")
	empty.free()
	print("CHARACTER WEAPON PROGRESSION ", "FAILED" if failed else "PASSED")
	quit(1 if failed else 0)