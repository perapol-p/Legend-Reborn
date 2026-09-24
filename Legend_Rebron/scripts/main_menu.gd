extends Control
func _ready():
    $Center/Menu/Play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/character_select.tscn"))
    $Center/Menu/Setting.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/settings.tscn"))
    $Center/Menu/Credit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/credits.tscn"))
    $Center/Menu/Controls.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/controls.tscn"))
    $Center/Menu/Exit.pressed.connect(func(): $QuitDialog.popup_centered())
    $QuitDialog.confirmed.connect(func(): get_tree().quit())
