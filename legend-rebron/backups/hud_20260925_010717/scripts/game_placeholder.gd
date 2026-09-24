extends Node3D
func _ready():
    $UI/Panel/VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
