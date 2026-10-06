extends SceneTree
const Run = preload("res://scripts/run_state.gd")
func _initialize() -> void:
	var run = Run.new()
	run.rng.seed = 485
	for seconds in [0.0,179.99,180.0,479.99,480.0,900.0,1200.0]:
		run.elapsed_time = seconds
		assert(run.rarity_weights(1) == run.rarity_weights(40))
		var counts := {"common":0,"rare":0,"epic":0,"legendary":0}
		for i in 1000:
			var choices := run.roll_choices(1)
			assert(choices.size() == 3 and choices[0] != choices[1] and choices[0] != choices[2] and choices[1] != choices[2])
			for id in choices:
				var rarity: String = run.catalog.item_for(id)["rarity"]
				assert(seconds >= {"common":0.0,"rare":0.0,"epic":180.0,"legendary":480.0}[rarity])
				counts[rarity] += 1
		print("PASS timed loot ",seconds,"s cards=",counts)
	run.elapsed_time = 180.0
	run.offers_without_high_rarity = 0
	var guarantees := 0
	for i in 300:
		var prior: int = run.offers_without_high_rarity
		run.pending_levels.assign([i+2])
		run._next_reward()
		assert(run.offers_without_high_rarity <= 5)
		if prior >= 5:
			var has_epic := false
			for id in run.offers:
				has_epic = has_epic or run.catalog.item_for(id)["rarity"] == "epic"
			assert(has_epic and run.offers_without_high_rarity == 0)
			guarantees += 1
	assert(guarantees > 0)
	run.elapsed_time = 0.0
	run.offers_without_high_rarity = 5
	run.pending_levels.assign([2])
	run._next_reward()
	assert(run.offers_without_high_rarity == 0)
	for id in run.offers:
		assert(run.catalog.item_for(id)["rarity"] in ["common","rare"])
	run.elapsed_time = 900.0
	var low: Dictionary = run.rarity_weights(40)
	run.offers.assign(["baby_oil"])
	assert(run.choose_item("baby_oil"))
	var high: Dictionary = run.rarity_weights(40)
	assert(high["epic"] > low["epic"] and high["legendary"] > low["legendary"])
	print("PASS level-independent unlocks, pity triggered ",guarantees," times, no early pity bypass, Luck still improves rewards")
	run.free()
	quit()
