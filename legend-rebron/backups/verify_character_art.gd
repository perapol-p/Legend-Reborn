extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 create_timer(20.0,true,false,true).timeout.connect(func(): quit(1))
 var data = root.get_node("GameData")
 data.active_run_path = "user://test_character_art.save"
 data.progress_path = "user://test_character_art_progress.cfg"
 data.selected_stage = "practice"
 var cfg := ConfigFile.new()
 cfg.set_value("characters","unlocked",["Daddy","Mommy","Son"])
 cfg.set_value("progress","games_completed",2)
 assert(cfg.save(data.progress_path) == OK)
 data.load_progress()
 assert(data.unlocked_characters == ["Saber","Archer","Wizard god"])
 assert(data.games_completed == 2)
 assert(data.normalize_character("mommy") == "Archer")
 assert(data.normalize_character("son") == "Wizard god")
 var select = load("res://scenes/character_select.tscn").instantiate()
 root.add_child(select)
 current_scene = select
 assert(select.character_buttons.size() == 3)
 assert(select.find_children("CharacterImage","TextureRect",true,false).size() == 3)
 for character in data.CHARACTERS:
  assert(data.character_icon(character) != null)
  assert(not select.character_buttons[character].disabled)
 await process_frame
 await process_frame
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://backups/character_cards_preview.png")
 select.queue_free()
 await process_frame
 await process_frame
 for character in data.CHARACTERS:
  data.selected_character = character
  var detail = load("res://scenes/character_detail.tscn").instantiate()
  root.add_child(detail)
  current_scene = detail
  assert(detail.find_children("CharacterImage","TextureRect",true,false).size() == 1)
  assert(detail.get_node("Center/Panel/VBox/Body/Detail").text.contains("Name: "+character))
  await process_frame
  await process_frame
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://backups/character_"+character.replace(" ","_")+"_preview.png")
  detail.queue_free()
  await process_frame
  await process_frame
  var game = load("res://scenes/game_placeholder.tscn").instantiate()
  game.auto_pause_on_focus_loss = false
  root.add_child(game)
  current_scene = game
  var combat = game.get_node("Player/Head/Camera3D/Combat")
  var expected: String = {"Saber":"sword","Archer":"bow","Wizard god":"spellbook"}[character]
  assert(combat.weapon_id == expected,character+" wrong base weapon")
  assert(game.get_node("RunState").character_name == character)
  if character == "Wizard god":
   game.command_console.submit("/unlock wizard god")
   assert(game.command_console.output.get_parsed_text().contains("Wizard god"))
   var saved = load("res://scripts/run_save_codec.gd").capture(game)
   saved["stage"] = "grassland"
   saved["run"]["character_name"] = "Son"
   saved["run"]["equipped_weapon_id"] = "sword"
   saved["run"]["weapon_levels"] = {"sword":4}
   saved["run"]["level"] = 31
   assert(data.save_active_run(saved) == OK)
   var restored: Dictionary = data.load_active_run()
   assert(restored["run"]["character_name"] == "Wizard god")
   assert(restored["run"]["equipped_weapon_id"] == "spellbook")
   assert(restored["run"]["weapon_levels"]["spellbook"] == 4)
   assert(restored["run"]["level"] == 31)
  game.queue_free()
  await process_frame
  await process_frame
 print("PASS: all 3 portrait cards/previews; Saber Sword, Archer Bow, Wizard god Staff; legacy unlocks/win count preserved; new multiword unlock; legacy Son save migrates to Staff retaining character/weapon levels")
 quit()
