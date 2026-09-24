extends SceneTree
const Run = preload("res://scripts/run_state.gd")
func _initialize() -> void:
	var run = Run.new()
	run.rng.seed = 12345
	assert(run.catalog.items.size() == 20)
	assert(run.catalog.by_id.size() == 20)
	var rarity_counts := {"common": 0, "rare": 0, "epic": 0, "legendary": 0}
	for item in run.catalog.items:
		rarity_counts[item["rarity"]] += 1
		assert(not item["effects"].is_empty())
	for count in rarity_counts.values():
		assert(count == 5)
	assert(run.catalog.item_for("red_dot")["effects"] == {"crit_chance": 1.0, "crit_damage": 2.0})
	assert(run.catalog.item_for("clover_three")["effects"]["luck"] == 0.5)
	assert(run.catalog.weapon_name("Knight") == "Sword")
	assert(run.catalog.weapon_name("Ninja") == "Katana")
	assert(run.catalog.weapon_name("Daddy") == "Not assigned")
	assert(run.catalog.data["weapons"].size() == 5)
	assert(run.level == 1 and run.offers.is_empty())
	run.add_xp(9)
	assert(run.level == 1 and run.xp == 9 and run.offers.is_empty())
	run.add_xp(1)
	assert(run.level == 2 and run.xp == 0 and run.offers.size() == 3)
	assert(not run.choose_item("not_an_item"))
	var offered: Array = run.offers.duplicate()
	var selected: String = offered[0]
	var before: Dictionary = run.stats()
	var effects: Dictionary = run.catalog.item_for(selected)["effects"]
	assert(run.choose_item(selected))
	for stat in effects:
		assert(is_equal_approx(float(run.stats()[stat]), float(before[stat] + effects[stat])))
	assert(not run.choose_item(selected))
	assert(run.owned_ids.size() == 1)
	for attempt in range(100):
		var sample: Array = run.roll_choices(2 + attempt)
		assert(sample.size() == 3)
		assert(sample[0] != sample[1] and sample[1] != sample[2] and sample[0] != sample[2])
		assert(not sample.has(selected))
	var early: Dictionary = run.rarity_weights(2)
	var late: Dictionary = run.rarity_weights(20)
	assert(early["common"] > late["common"])
	assert(early["rare"] < late["rare"])
	assert(early["epic"] < late["epic"])
	assert(early["legendary"] < late["legendary"])
	assert(run.rarity_weights(100) == late)
	var fresh = Run.new()
	var average: Array[float] = []
	var scores := {"common": 0, "rare": 1, "epic": 2, "legendary": 3}
	for at_level in [2, 20]:
		fresh.rng.seed = 887766
		var total := 0.0
		for attempt in range(500):
			for id in fresh.roll_choices(at_level):
				total += scores[fresh.catalog.item_for(id)["rarity"]]
		average.append(total / 1500.0)
	assert(average[1] > average[0] + 0.5)
	fresh.add_xp(45)
	assert(fresh.level == 4 and fresh.xp == 0)
	assert(fresh.reward_level == 2 and fresh.pending_levels.size() == 2)
	for expected in [2, 3, 4]:
		assert(fresh.reward_level == expected)
		assert(fresh.choose_item(fresh.offers[0]))
	assert(fresh.offers.is_empty() and fresh.owned_ids.size() == 3)
	assert(fresh.pending_levels.is_empty())
	fresh.free()
	while run.remaining_count() > 0:
		var remaining: int = run.remaining_count()
		run.test_level_up()
		assert(run.offers.size() == mini(3, remaining))
		for id in run.offers:
			assert(not run.owned_ids.has(id))
		assert(run.choose_item(run.offers[0]))
	assert(run.owned_ids.size() == 20)
	assert(run.stats()["max_hp"] == 620)
	assert(run.stats()["attack"] == 300)
	assert(run.stats()["speed"] == 125)
	assert(run.stats()["luck"] == 8.5)
	assert(run.stats()["crit_chance"] == 23.5)
	assert(run.stats()["crit_damage"] == 187)
	run.test_level_up()
	assert(run.offers.is_empty() and run.pending_levels.is_empty())
	assert(run.owned_ids.size() == 20)
	run.free()
	print("PASS: catalog, bonus math, unique offers/ownership, rarity scaling, XP queue, 2/1/0 remaining, weapon metadata")
	quit()
