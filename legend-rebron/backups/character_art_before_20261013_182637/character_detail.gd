extends Control
func _ready():
    $Center/Panel/VBox/Body/Portrait.text = GameData.selected_character + "\n\n[ Character Preview ]"
    var catalog = preload("res://scripts/item_catalog.gd").new()
    var role := "Archer" if GameData.selected_character == "Mommy" else "Adventurer"
    $Center/Panel/VBox/Body/Detail.text = "CHARACTER DETAIL\n\nName: %s\nRole: %s\nBase weapon: %s\nStage: %s\nMode: %s" % [GameData.selected_character, role, catalog.weapon_name(GameData.selected_character), GameData.STAGE_NAMES[GameData.selected_stage], "Sandbox" if GameData.selected_stage == "practice" else "Normal Mode"]
    $Center/Panel/VBox/Buttons/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/character_select.tscn"))
    $Center/Panel/VBox/Buttons/Go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game_placeholder.tscn"))



