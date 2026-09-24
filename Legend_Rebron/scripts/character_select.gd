extends Control
func _ready():
    $Center/VBox/Cards/Daddy.pressed.connect(func(): _select("Daddy"))
    $Center/VBox/Cards/Mommy.pressed.connect(func(): _select("Mommy"))
    $Center/VBox/Cards/Son.pressed.connect(func(): _select("Son"))
    $Center/VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
    if GameData.games_completed < 1:
        $Center/VBox/Cards/Mommy.disabled = true
        $Center/VBox/Cards/Mommy.text = "Mommy\nLOCKED - Pass 1 Game"
    $Center/VBox/Cards/Son.disabled = true
    $Center/VBox/Cards/Son.text = "Son\nLOCKED"
func _select(name: String):
    GameData.selected_character = name
    get_tree().change_scene_to_file("res://scenes/character_detail.tscn")
