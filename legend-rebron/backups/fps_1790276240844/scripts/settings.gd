extends Control
@onready var master = $Center/Panel/VBox/Master
@onready var music = $Center/Panel/VBox/Music
@onready var effects = $Center/Panel/VBox/Effects
@onready var sensitivity = $Center/Panel/VBox/Sensitivity
@onready var fullscreen = $Center/Panel/VBox/Fullscreen
@onready var invert_y = $Center/Panel/VBox/InvertY
func _ready():
    master.value = GameData.master_volume * 100.0
    music.value = GameData.music_volume * 100.0
    effects.value = GameData.effects_volume * 100.0
    sensitivity.value = GameData.mouse_sensitivity * 100.0
    fullscreen.button_pressed = GameData.fullscreen
    invert_y.button_pressed = GameData.invert_y
    master.value_changed.connect(_changed)
    music.value_changed.connect(_changed)
    effects.value_changed.connect(_changed)
    sensitivity.value_changed.connect(_changed)
    fullscreen.toggled.connect(func(_v): _changed(0))
    invert_y.toggled.connect(func(_v): _changed(0))
    $Center/Panel/VBox/Restore.pressed.connect(_restore)
    $Center/Panel/VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
func _changed(_v):
    GameData.master_volume = master.value / 100.0
    GameData.music_volume = music.value / 100.0
    GameData.effects_volume = effects.value / 100.0
    GameData.mouse_sensitivity = sensitivity.value / 100.0
    GameData.fullscreen = fullscreen.button_pressed
    GameData.invert_y = invert_y.button_pressed
    GameData.apply_settings()
    GameData.save_settings()
func _restore():
    GameData.restore_defaults()
    master.value = GameData.master_volume * 100.0
    music.value = GameData.music_volume * 100.0
    effects.value = GameData.effects_volume * 100.0
    sensitivity.value = GameData.mouse_sensitivity * 100.0
    fullscreen.button_pressed = GameData.fullscreen
    invert_y.button_pressed = GameData.invert_y
