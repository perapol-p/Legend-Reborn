extends Control
func _ready():
    $Center/Panel/VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
