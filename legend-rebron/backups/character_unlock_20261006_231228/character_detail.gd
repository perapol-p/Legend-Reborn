extends Control
func _ready():
    $Center/Panel/VBox/Body/Portrait.text = GameData.selected_character + "\n\n[ Character Preview ]"
    $Center/Panel/VBox/Body/Detail.text = "CHARACTER DETAIL\n\nName: %s\n\nThis area is ready for character story, stats and abilities.\n\nThe 3D gameplay scene will be connected later." % GameData.selected_character
    $Center/Panel/VBox/Buttons/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/character_select.tscn"))
    $Center/Panel/VBox/Buttons/Go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game_placeholder.tscn"))
