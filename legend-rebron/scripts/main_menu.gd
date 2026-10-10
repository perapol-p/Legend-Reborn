extends Control
func _ready():
    var saved: Dictionary = GameData.load_active_run()
    $Center/Menu/Continue.visible = not saved.is_empty()
    $Center/Menu/Continue.pressed.connect(continue_run)
    if not saved.is_empty():
        var seconds := int(saved["run"]["elapsed_time"])
        $Center/Menu/Continue.text = "CONTINUE\n%s / %s / LV %d / %02d:%02d" % [GameData.STAGE_NAMES[saved["stage"]], saved["run"]["character_name"], saved["run"]["level"], seconds/60,seconds%60]
    $Center/Menu/Play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/stage_select.tscn"))
    $Center/Menu/Setting.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/settings.tscn"))
    $Center/Menu/Credit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/credits.tscn"))
    $Center/Menu/Controls.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/controls.tscn"))
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
    get_tree().change_scene_to_file("res://scenes/game_placeholder.tscn")
