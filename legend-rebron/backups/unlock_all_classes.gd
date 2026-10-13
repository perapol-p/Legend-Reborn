extends SceneTree
func _initialize(): call_deferred("unlock_classes")
func unlock_classes():
 var data = root.get_node("GameData")
 for character in data.CHARACTERS:
  assert(data.unlock_character(character))
 var cfg := ConfigFile.new()
 assert(cfg.load(data.progress_path) == OK)
 var saved = cfg.get_value("characters","unlocked",[])
 for character in data.CHARACTERS:
  assert(data.is_character_unlocked(character) and character in saved)
 print("UNLOCKED: ",", ".join(data.CHARACTERS))
 print("Saved to: ",ProjectSettings.globalize_path(data.progress_path))
 quit()
