extends Node3D
func _ready() -> void:
	$RunState.character_name = GameData.selected_character
	$Interface/HUD.bind_combo($Combo)
	$Interface/HUD.bind_run($RunState)
	$Interface/HUD.level_up_requested.connect(_test_level_up)
	$Interface/PauseOverlay.bind_run($RunState)
	$Interface/RewardOverlay.bind_run($RunState)
	$RunState.offers_changed.connect(_sync_reward)
func _test_level_up() -> void:
	if not get_tree().paused:
		$RunState.test_level_up()
func _sync_reward() -> void:
	$Interface/RewardOverlay.refresh()
	get_tree().paused = $Interface/RewardOverlay.visible or $Interface/PauseOverlay.visible
	if not get_tree().paused:
		get_viewport().gui_release_focus()
