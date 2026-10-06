extends Control
var command_console: PanelContainer
func _ready():
    command_console = preload("res://scripts/command_console.gd").attach_to_lobby(self)
    $Center/Panel/VBox/Body/Portrait.text = GameData.selected_character + "\n\n[ Character Preview ]"
    var catalog = preload("res://scripts/item_catalog.gd").new()
    var role := "Archer" if GameData.selected_character == "Mommy" else "Adventurer"
    $Center/Panel/VBox/Body/Detail.text = "CHARACTER DETAIL\n\nName: %s\nRole: %s\nBase weapon: %s" % [GameData.selected_character, role, catalog.weapon_name(GameData.selected_character)]
    $Center/Panel/VBox/Buttons/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/character_select.tscn"))
    $Center/Panel/VBox/Buttons/Go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game_placeholder.tscn"))

