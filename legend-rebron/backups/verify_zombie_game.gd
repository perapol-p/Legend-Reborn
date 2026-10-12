extends SceneTree
func _initialize():
 call_deferred("verify")
func verify():
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_zombie_run.save"
 data.progress_path = "user://test_zombie_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 await physics_frame
 await physics_frame
 var spawner = game.get_node("MonsterSpawner")
 var zombie = spawner.spawn_one(false,"melee",true)
 assert(zombie != null and zombie.zombie_visual != null)
 var start = zombie.global_position
 await create_timer(0.8).timeout
 assert(zombie.global_position.distance_to(start) > 0.3)
 assert(zombie.zombie_visual.animation_player.current_animation == "Armature|Walk")
 assert(zombie.zombie_visual.get_node("ZombieAsset").rotation.y == 0.0)
 var archer = spawner.spawn_one(false,"archer",true)
 var flyer = spawner.spawn_one(false,"flyer",true)
 assert(archer != null and flyer != null)
 assert(archer.zombie_visual == null and flyer.zombie_visual == null)
 zombie.take_damage(999999)
 await create_timer(1).timeout
 assert(not is_instance_valid(zombie))
 print("PASS: actual practice game spawns moving zombie, death cleanup, original ranged enemies")
 game.queue_free()
 await process_frame
 await process_frame
 quit()