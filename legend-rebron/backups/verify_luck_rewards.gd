extends SceneTree
const Run = preload("res://scripts/run_state.gd")
func _initialize() -> void:
	var run = Run.new()
	for luck in [0.0,30.0,100.0]:
		run.catalog.data["base_stats"]["luck"] = luck
		run.rng.seed = 788
		for level in [1,5,12,25,60]:
			var counts := {"common":0,"rare":0,"epic":0,"legendary":0}
			for roll in 1000:
				var choices := run.roll_choices(level)
				assert(choices.size() == 3 and choices[0] != choices[1] and choices[0] != choices[2] and choices[1] != choices[2])
				for id in choices:
					var rarity: String = run.catalog.item_for(id)["rarity"]
					assert(level >= {"common":1,"rare":5,"epic":12,"legendary":25}[rarity])
					counts[rarity] += 1
			print("PASS luck=",luck," LV",level," 3000 cards=",counts)
		run.catalog.data["base_stats"]["luck"] = luck
		var weights: Dictionary = run.rarity_weights(60)
		var total := 0.0
		for weight in weights.values():
			total += float(weight)
		print("Legendary chance/card at LV60 luck",luck,"=",float(weights["legendary"])/total*100.0,"%")
	run.catalog.data["base_stats"]["luck"] = 0.0
	var before: Dictionary = run.rarity_weights(60)
	run.offers.assign(["clover_three"])
	assert(run.choose_item("clover_three"))
	assert(run.stats()["luck"] == 5.0)
	var after: Dictionary = run.rarity_weights(60)
	assert(after["rare"] > before["rare"] and after["epic"] > before["epic"] and after["legendary"] > before["legendary"])
	assert(after["common"] == before["common"])
	assert(run.stats()["crit_chance"] == 5.0)
	print("PASS actual equipped Luck item affects rarity weights, gates and crit chance unchanged")
	run.free()
	quit()
