extends Node

const SAVE_PATH := "user://settings.cfg"
var selected_character := "Daddy"
var games_completed := 0
var master_volume := 0.8
var music_volume := 0.7
var effects_volume := 0.8
var mouse_sensitivity := 0.5
var fullscreen := false
var invert_y := false

func _ready():
    load_settings()
    apply_settings()

func save_settings():
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "master", master_volume)
    cfg.set_value("audio", "music", music_volume)
    cfg.set_value("audio", "effects", effects_volume)
    cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
    cfg.set_value("display", "fullscreen", fullscreen)
    cfg.set_value("controls", "invert_y", invert_y)
    cfg.save(SAVE_PATH)

func load_settings():
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    master_volume = cfg.get_value("audio", "master", master_volume)
    music_volume = cfg.get_value("audio", "music", music_volume)
    effects_volume = cfg.get_value("audio", "effects", effects_volume)
    mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
    fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
    invert_y = cfg.get_value("controls", "invert_y", invert_y)

func apply_settings():
    AudioServer.set_bus_volume_db(0, linear_to_db(max(master_volume, 0.001)))
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func restore_defaults():
    master_volume = 0.8
    music_volume = 0.7
    effects_volume = 0.8
    mouse_sensitivity = 0.5
    fullscreen = false
    invert_y = false
    apply_settings()
    save_settings()
