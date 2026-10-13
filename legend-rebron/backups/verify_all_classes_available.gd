extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
 var data = root.get_node("GameData")
 assert(data.unlocked_characters.size()==3)
 data.progress_path = "user://test_all_classes_fresh.cfg"
 data.unlocked_characters.assign(["Saber"])
 data.load_progress()
 for name in data.CHARACTERS: assert(data.is_character_unlocked(name))
 assert(data.unlocked_characters.size()==3)
 assert(not data.is_character_unlocked("unknown"))
 var cfg := ConfigFile.new()
 cfg.set_value("characters","unlocked",["Daddy"])
 cfg.set_value("progress","games_completed",7)
 data.progress_path = "user://test_all_classes_old.cfg"
 cfg.save(data.progress_path)
 data.load_progress()
 assert(data.games_completed==7 and data.unlocked_characters.size()==3)
 for alias in ["Daddy","Mommy","Son"]: assert(data.is_character_unlocked(alias))
 data.save_progress()
 cfg.load(data.progress_path)
 assert(cfg.get_value("characters","unlocked",[]).size()==3)
 data.selected_stage = "practice"
 var screen = load("res://scenes/character_select.tscn").instantiate()
 root.add_child(screen)
 for button in screen.character_buttons.values(): assert(not button.disabled)
 screen.queue_free()
 await process_frame
 print("PASS: all classes available on fresh profile and old locked profile, wins preserved, invalid names rejected, all selection buttons enabled")
 quit()
