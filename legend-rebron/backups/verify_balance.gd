extends SceneTree
const Run = preload("res://scripts/run_state.gd")
func _initialize() -> void:
	var run = Run.new()
	run.rng.seed = 2047
	var unlocks := {"common":1,"rare":5,"epic":12,"legendary":25}
	for level in [1,4,5,11,12,24,25,40,60]:
		var counts := {"common":0,"rare":0,"epic":0,"legendary":0}
		for roll in 1000:
			var choices: Array = run.roll_choices(level)
			assert(choices.size() == 3)
			assert(choices[0] != choices[1] and choices[0] != choices[2] and choices[1] != choices[2])
			for id in choices:
				var rarity: String = run.catalog.item_for(id)["rarity"]
				assert(level >= unlocks[rarity], "Locked rarity appeared at LV%d" % level)
				counts[rarity] += 1
		if level >= 5:
			assert(counts["rare"] > 0)
		if level >= 12:
			assert(counts["epic"] > 0)
		if level >= 25:
			assert(counts["legendary"] > 0 and counts["legendary"] < 120)
		print("PASS reward LV",level," 3000 cards, rarity counts=",counts)
	var spawner = load("res://scripts/monster_spawner.gd").new()
	assert(spawner.initial_count == 6 and spawner.max_alive == 100 and spawner.max_batch_size == 12)
	for sample in [[0.0,40.0],[60.0,76.0],[180.0,184.0],[300.0,340.0],[600.0,940.0],[1200.0,3040.0]]:
		spawner.survival_time = sample[0]
		assert(is_equal_approx(spawner.monster_health(), sample[1]))
	print("PASS higher monster HP curve, stronger bounded spawn settings, item rarity unlocks and low Legendary weight")
	run.free()
	spawner.free()
	quit()
