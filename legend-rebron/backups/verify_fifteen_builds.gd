extends SceneTree
const Run = preload("res://scripts/run_state.gd")
func _initialize() -> void:
	var spawner = load("res://scripts/monster_spawner.gd").new()
	var builds := [[],["pencil","pencil","pan"],["pencil","pencil","pencil","pan","pan","light_saber"],["pencil","pencil","pencil","pencil","pan","pan","pan","light_saber","light_saber","zenith"]]
	var times := [0.0,300.0,600.0,900.0]
	for i in 4:
		var run = Run.new()
		for id in builds[i]:
			run.offers.assign([id])
			assert(run.choose_item(id))
		spawner.survival_time = times[i]
		var hp: float = spawner.monster_health()
		var atk: float = run.stats()["attack"]
		var sword_hits := ceili(hp/(atk*1.3))
		var gun_hits := ceili(hp/atk)
		var bow_hits := ceili(hp/(atk*2.0))
		assert(sword_hits <= 4 and gun_hits <= 4 and bow_hits <= 2)
		print("Build @",times[i]/60," min ATK",atk," HP",hp," hits(noncrit) sword/gun/bow=",sword_hits,"/",gun_hits,"/",bow_hits)
		run.free()
	var run = Run.new()
	run.elapsed_time = 120.0
	run.rng.seed = 249
	var guarantees := 0
	for i in 150:
		var previous: int = run.offers_without_high_rarity
		run.pending_levels.assign([8])
		run._next_reward()
		assert(run.offers_without_high_rarity <= 5)
		if previous >= 5:
			var epic := false
			for id in run.offers:
				epic = epic or run.catalog.item_for(id)["rarity"] == "epic"
			assert(epic)
			guarantees += 1
	assert(guarantees > 0)
	run.elapsed_time = 600.0
	assert(run.rarity_weights(1)["epic"] == 0 and run.rarity_weights(1)["legendary"] == 0)
	print("PASS sample build hit counts and gated pity; guarantees=",guarantees)
	run.free()
	spawner.free()
	quit()
