extends Control
var command_console: PanelContainer
func _ready() -> void:
	$Center/VBox/Cards/Daddy.pressed.connect(func(): _select("Daddy"))
	$Center/VBox/Cards/Mommy.pressed.connect(func(): _select("Mommy"))
	$Center/VBox/Cards/Son.pressed.connect(func(): _select("Son"))
	$Center/VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	GameData.characters_changed.connect(_refresh_characters)
	_refresh_characters()
	command_console = preload("res://scripts/command_console.gd").attach_to_lobby(self)
func _refresh_characters() -> void:
	for character in GameData.CHARACTERS:
		var card := get_node("Center/VBox/Cards/" + character) as Button
		var unlocked := GameData.is_character_unlocked(character)
		card.disabled = not unlocked
		var role := "\nARCHER / BOW" if character == "Mommy" else ""
		card.text = character + role + ("\nAVAILABLE" if unlocked else ("\nLOCKED - Pass 1 Game" if character == "Mommy" else "\nLOCKED"))
func _select(character: String) -> void:
	if not GameData.is_character_unlocked(character):
		return
	GameData.selected_character = character
	get_tree().change_scene_to_file("res://scenes/character_detail.tscn")
