extends Node
const Codec = preload("res://scripts/run_save_codec.gd")
const Run = preload("res://scripts/run_state.gd")
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _ready() -> void:
	GameData.selected_stage = "practice"
	GameData.selected_character = "Wizard god"
	GameData.pending_resume = {}
	var game = load("res://scenes/game_placeholder.tscn").instantiate()
	game.auto_pause_on_focus_loss = false
	game.get_node("MonsterSpawner").enabled = false
	var mount_game := func():
		get_tree().root.add_child(game)
		get_tree().current_scene = game
	mount_game.call_deferred()
	await get_tree().process_frame
	await get_tree().process_frame
	var run = game.get_node("RunState")
	var reward = game.get_node("Interface/RewardOverlay")
	var pause = game.get_node("Interface/PauseOverlay")
	var hud = game.get_node("Interface/HUD")
	var player = game.get_node("Player")
	var combat = player.get_node("Head/Camera3D/Combat")
	for weapon in ["sword","bow","spellbook"]:
		combat.equip(weapon)
		check(hud.weapon_label.text == run.character_name and hud.weapon_level_label.text.begins_with(run.Progression.display_name(weapon)), "HUD displays character name above weapon type")
		for choice in run.Progression.UPGRADES[weapon]:
			run.test_level_up()
			check(reward.visible and get_tree().paused, "Item reward pauses gameplay")
			reward.choice_buttons[0].pressed.emit()
			check(run.reward_phase == "weapon" and reward.choice_buttons.size() == 3 and get_tree().paused and not player.input_enabled, "Weapon choices follow item and remain paused")
			check(reward.heading.text.begins_with("Level ") and not reward.heading.text.contains("Choose"), "Heading only shows level")
			check(reward.find_children("WeaponStatsPanel", "", true, false).is_empty(), "Level Up contains only choices, without weapon stats")
			if weapon == "spellbook":
				check(run.offers == ["cast_speed", "storm_cooldown", "explosion_size"], "Only three composite Staff choices")
			if OS.get_cmdline_user_args().has("--preview") and choice == run.Progression.UPGRADES[weapon][-1]:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://backups/weapon_stats_%s.png" % weapon)
			var copy = Run.new()
			Codec.apply(copy,Codec.fields(run,Codec.RUN_FIELDS),Codec.RUN_FIELDS)
			check(copy.choose_weapon_upgrade(choice,copy.offer_generation), "Save restores pending choice")
			reward._choose(choice,run.offer_generation)
			check(copy.weapon_upgrades == run.weapon_upgrades, "Saved ranks match")
			copy.free()
			check(pause.weapon_stats_panel.values.text == run.Progression.stat_text(run.weapon_stats(weapon),weapon), "Tab stats update immediately after selection")
			check(not reward.visible and not get_tree().paused and player.input_enabled, "Choosing upgrade resumes gameplay")
		check(combat.attack_cooldown() < float(combat.WEAPONS[weapon]["cooldown"]), "Attack speed affects combat")
		if weapon == "bow":
			var before: int = combat.projectiles_fired
			combat.resolve_attack()
			check(combat.projectiles_fired-before == 2, "Projectile upgrade adds an arrow")
			for shot in get_tree().get_nodes_in_group("weapon_projectiles"):
				if shot.kind == "bow": check(shot.pierces_remaining == 1, "Pierce upgrade adds one additional enemy")
		elif weapon == "sword":
			combat.resolve_attack()
			for shot in get_tree().get_nodes_in_group("weapon_projectiles"):
				if shot.kind == "sword_wave":
					check(shot.speed > 14.0 and shot.travel_remaining > 6.0 and shot.hit_radius > 0.4 and shot.wave_vfx.radius > 1.25, "Sword upgrades change range, speed, visible size and collision")
		else:
			check(run.weapon_stats("spellbook")["storm_cooldown"] < 8.0 and run.weapon_stats("spellbook")["storm_spawn_radius"] == 10.0, "Storm upgrade reduces cooldown with fixed 10 m spawn radius")
			check(combat.try_explosion(), "Explosion available without level milestone")
			for effect in get_tree().get_nodes_in_group("staff_explosions"):
				check(effect.radius > 27.0, "Explosion upgrade enlarges actual radius")
		for shot in get_tree().get_nodes_in_group("weapon_projectiles")+get_tree().get_nodes_in_group("staff_explosions"):
			shot.queue_free()
		await get_tree().process_frame
	check(hud.find_children("WeaponStatsPanel", "", true, false).is_empty(), "Gameplay HUD is a compact weapon summary without a background panel")
	pause.toggle_stats()
	check(pause.visible and pause.equipment.visible and pause.weapon_stats_panel.values.text.contains("Storm"), "Tab displays detailed weapon stats")
	if OS.get_cmdline_user_args().has("--preview"):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/weapon_stats_tab.png")
	pause._close_overlay()
	if OS.get_cmdline_user_args().has("--preview"):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://backups/weapon_stats_hud.png")
	combat.equip("spellbook")
	combat.storm_cooldown = 0.0
	for effect in get_tree().get_nodes_in_group("weapon_tornadoes"): effect.queue_free()
	await get_tree().process_frame
	var positions: Array[Vector3] = []
	for i in range(20):
		var storm = combat.spawn_random_storm()
		check(storm != null, "Random storm finds valid ground")
		if storm == null: continue
		var offset: Vector3 = storm.global_position-player.global_position
		offset.y = 0.0
		check(offset.length() <= 10.001 and storm.remaining <= 2.5, "Storm spawns within 10 m with finite duration")
		positions.append(storm.global_position)
		var original: Vector3 = storm.global_position
		player.global_position.x += 0.1
		storm._physics_process(0.01)
		check(storm.global_position.is_equal_approx(original), "Storm remains at spawn point")
		player.global_position.x -= 0.1
		storm.queue_free()
	check(positions.size() > 1 and not positions[0].is_equal_approx(positions[-1]), "Storm locations are randomized")
	await get_tree().process_frame
	combat.storm_cooldown = 1.0
	var before: int = combat.tornadoes_created
	combat._tick_storm(0.5)
	check(combat.tornadoes_created == before, "Cooldown prevents early storm spawn")
	combat._tick_storm(0.5)
	check(combat.tornadoes_created == before+1, "Cooldown expiry creates one storm")
	for rank in [0,4,5,9,10,14,15]:
		run.weapon_upgrades["spellbook"]["storm_cooldown"] = rank
		run.changed.emit()
		var expected := 1 + floori(float(rank)/5.0)
		check(run.weapon_stats("spellbook")["storm_spawn_count"] == expected, "Storm count increases every five selected upgrades")
		check(pause.weapon_stats_panel.values.text.contains("Per Spawn : %d" % expected), "Tab displays actual storm count per spawn")
		combat.storm_cooldown = 0.0
		before = combat.tornadoes_created
		combat._tick_storm(0.0)
		check(combat.tornadoes_created == before+expected, "Cooldown expiry spawns the complete storm batch")
		check(combat.storm_cooldown > 0.0, "Batch uses one shared cooldown")
		for effect in get_tree().get_nodes_in_group("weapon_tornadoes"):
			if effect.is_queued_for_deletion(): continue
			var offset: Vector3 = effect.global_position-player.global_position
			offset.y = 0.0
			check(offset.length() <= 10.001, "Every storm in batch spawns inside 10 m")
			effect.queue_free()
	run.weapon_upgrades["spellbook"]["storm_cooldown"] = 1
	run.changed.emit()
	get_tree().paused = true
	var saved: Dictionary = Codec.capture(game)
	check(saved["combat"].has("storm_cooldown"), "Checkpoint preserves storm timer")
	for effect in get_tree().get_nodes_in_group("weapon_tornadoes"): effect.queue_free()
	await get_tree().process_frame
	Codec.restore_world(game,saved)
	check(is_equal_approx(combat.storm_cooldown,saved["combat"]["storm_cooldown"]), "Continue restores storm cooldown")
	var previous := {"run":{"weapon_levels":{"spellbook":3},"weapon_upgrades":{"spellbook":{"storm":2}},"reward_phase":"weapon","upgrade_weapon_id":"spellbook","offers":["cast_speed","storm","explosion_size"]},"tornadoes":[{"source_weapon":"spellbook","follow_player":true}]}
	Codec.migrate_removed_weapons(previous)
	check(previous["run"]["weapon_upgrades"]["spellbook"]["storm_cooldown"] == 2 and previous["run"]["offers"][1] == "storm_cooldown" and previous["tornadoes"].is_empty(), "Orbit saves migrate to random cooldown storms")
	var legacy := {"run":{"weapon_levels":{"sword":5},"equipped_weapon_id":"sword"}}
	Codec.migrate_removed_weapons(legacy)
	check(legacy["run"]["weapon_upgrades"]["sword"]["attack_speed"] == 2, "Legacy levels migrate to new ranks")
	print("WEAPON UPGRADE INTEGRATION ", "FAILED" if failed else "PASSED")
	for effect in get_tree().get_nodes_in_group("weapon_tornadoes"):
		effect.queue_free()
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failed else 0)
