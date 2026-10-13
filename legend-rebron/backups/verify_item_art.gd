extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_item_art.save"
 data.progress_path = "user://test_item_art_progress.cfg"
 data.selected_stage = "practice"
 var game = load("res://scenes/game_placeholder.tscn").instantiate()
 game.auto_pause_on_focus_loss = false
 root.add_child(game)
 current_scene = game
 var run = game.get_node("RunState")
 var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://backups/item_art_before_20261013_161844/item_catalog.json"))
 assert(run.catalog.items.size() == 20)
 for item in run.catalog.items:
  assert(run.catalog.icon_for(item) != null,item["name"]+" missing image")
  assert(item["name"] == str(item["icon"]).get_file().get_basename())
  var original: Dictionary
  for old in before["items"]:
   if old["id"] == item["id"]: original = old
  assert(item["effects"] == original["effects"] and item["rarity"] == original["rarity"])
 assert(run.catalog.item_for("golden_dick")["name"] == "Golden banana")
 assert(run.catalog.item_for("scope_x2")["name"] == "Scope holo")
 assert(run.catalog.item_for("god_eyes")["name"] == "God eye")
 run.reward_level = 40
 run.offer_generation = 1
 run.offers.assign(["golden_dick","god_eyes","pan"])
 game._sync_reward()
 await process_frame
 await process_frame
 var reward = game.get_node("Interface/RewardOverlay")
 assert(reward.choice_buttons.size() == 3)
 var bounds: Vector2 = root.get_visible_rect().size
 for panel in reward.cards.get_children():
  var stack = panel.get_child(0)
  var art = stack.get_node("ItemArtwork")
  var image = art.get_node("ItemImage")
  var name_label = stack.get_node("ItemName")
  assert(image.texture != null)
  assert(name_label.global_position.y >= art.global_position.y+art.size.y)
  assert(panel.global_position.x >= 0.0 and panel.global_position.x+panel.size.x <= bounds.x+0.1)
  assert(panel.global_position.y+panel.size.y <= bounds.y-10.0)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/item_rewards_preview.png")
 var hp_before: float = run.stats()["max_hp"]
 reward._choose("golden_dick",run.offer_generation)
 assert(run.stack_count("golden_dick") == 1)
 assert(run.stats()["max_hp"] == hp_before+150.0)
 for item in run.catalog.items:
  if not run.owned_ids.has(item["id"]): run.owned_ids.append(item["id"])
  run.item_counts[item["id"]] = 2
 run.changed.emit()
 var pause = game.get_node("Interface/PauseOverlay")
 pause.show()
 pause.show_inventory()
 paused = true
 await process_frame
 await process_frame
 assert(pause.item_flow.find_children("ItemImage","TextureRect",true,false).size() == 20)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/item_inventory_preview.png")
 pause.hide()
 var layer := CanvasLayer.new()
 layer.layer = 250
 game.add_child(layer)
 var results = load("res://scripts/run_result_overlay.gd").new()
 results.summary = run.result_summary()
 layer.add_child(results)
 await process_frame
 await process_frame
 assert(results.find_children("ItemImage","TextureRect",true,false).size() == 20)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/item_results_preview.png")
 var codec = load("res://scripts/run_save_codec.gd")
 var saved = codec.capture(game)
 assert(saved["run"]["owned_ids"].has("golden_dick"))
 assert(saved["run"]["item_counts"]["golden_dick"] == 2)
 print("PASS: all 20 images and exact file names; item IDs/rarities/stats preserved; image above name; reward choices fit screen and apply bonus; inventory/results show 20 icons; existing save IDs/stacks preserved")
 game.queue_free()
 await process_frame
 await process_frame
 quit()
