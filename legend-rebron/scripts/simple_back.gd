extends Control
func _ready():
    $Center/Panel/VBox/Back.pressed.connect(func(): SceneTransition.change_scene("res://scenes/main_menu.tscn"))
