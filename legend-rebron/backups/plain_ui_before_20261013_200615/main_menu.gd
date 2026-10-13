extends Control
const Style = preload("res://scripts/ui_style.gd")
var background: Control
func _ready():
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    $BG.hide()
    background = preload("res://scripts/home_background.gd").new()
    background.name = "HomeWorlds"
    add_child(background)
    move_child(background,0)
    $Center/Menu/Title.add_theme_color_override("font_color",Style.PAPER)
    $Center/Menu/Subtitle.add_theme_color_override("font_color",Color("bdc9c2"))
    for button in [$Center/Menu/Play,$Center/Menu/Continue,$Center/Menu/Setting,$Center/Menu/Credit,$Center/Menu/Exit]:
        button.add_theme_font_size_override("font_size",18)
        button.add_theme_color_override("font_color",Style.PAPER)
        button.add_theme_stylebox_override("normal",Style.box(Color(0.07,0.10,0.12,0.9),Color("52635e"),10))
        button.add_theme_stylebox_override("hover",Style.box(Color(0.17,0.22,0.20,0.95),Style.GOLD,10))
        button.add_theme_stylebox_override("pressed",Style.box(Color(0.24,0.28,0.21,0.95),Style.GOLD,10))
        button.add_theme_stylebox_override("focus",Style.box(Color(0.17,0.22,0.20,0.95),Style.GOLD,10))
    $Center/Menu/Play.add_theme_stylebox_override("normal",Style.box(Color(0.20,0.25,0.17,0.95),Style.GOLD,10))
    $Center/Menu/Title.text = "LEGEND\nREBORN"
    $Center/Menu/Title.add_theme_font_size_override("font_size",62)
    $Center/Menu/Subtitle.text = "One life. Endless hordes.\nDefeat the golem. Become a legend."
    $Center/Menu/Subtitle.add_theme_font_size_override("font_size",18)
    $Center/Menu/Subtitle.add_theme_color_override("font_color",Style.MUTED)
    $Center/Menu.add_theme_constant_override("separation",14)
    $Center/Menu/Play.text = "PLAY  /  NEW RUN"
    $Center/Menu/Setting.text = "SETTINGS"
    $Center/Menu/Credit.text = "CREDITS"
    $Center/Menu/Exit.text = "QUIT"
    Style.primary($Center/Menu/Play)
    var footer := Style.caption(self,"LEGEND REBORN  /  SURVIVAL",12)
    footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    footer.position = Vector2(48,get_viewport_rect().size.y-38)
    var saved: Dictionary = GameData.load_active_run()
    $Center/Menu/Continue.visible = not saved.is_empty()
    $Center/Menu/Continue.pressed.connect(continue_run)
    if not saved.is_empty():
        var seconds := int(saved["run"]["elapsed_time"])
        $Center/Menu/Continue.text = "CONTINUE\n%s / %s / LV %d / %02d:%02d" % [GameData.STAGE_NAMES[saved["stage"]], saved["run"]["character_name"], saved["run"]["level"], seconds/60,seconds%60]
    $Center/Menu/Play.pressed.connect(func(): SceneTransition.change_scene("res://scenes/stage_select.tscn"))
    $Center/Menu/Setting.pressed.connect(func(): SceneTransition.change_scene("res://scenes/settings.tscn"))
    $Center/Menu/Credit.pressed.connect(func(): SceneTransition.change_scene("res://scenes/credits.tscn"))
    $Center/Menu/Exit.pressed.connect(func(): $QuitDialog.popup_centered())
    $QuitDialog.confirmed.connect(func(): get_tree().quit())




func continue_run() -> void:
    var saved: Dictionary = GameData.load_active_run()
    if saved.is_empty():
        $Center/Menu/Continue.hide()
        return
    GameData.pending_resume = saved
    GameData.selected_stage = saved["stage"]
    GameData.selected_character = saved["run"]["character_name"]
    get_tree().paused = false
    SceneTransition.change_scene("res://scenes/game_placeholder.tscn")
