extends Node3D
@export var auto_pause_on_focus_loss := true
var cursor_released := false
func _ready() -> void:
	$RunState.character_name = GameData.selected_character
	$Player.bind_run($RunState)
	$Interface/HUD.bind_combo($Combo)
	$Interface/HUD.bind_run($RunState)
	$Interface/HUD.level_up_requested.connect(_test_level_up)
	$Interface/PauseOverlay.bind_run($RunState)
	$Interface/PauseOverlay.pause_changed.connect(_pause_changed)
	$Interface/RewardOverlay.bind_run($RunState)
	$RunState.offers_changed.connect(_sync_reward)
	_update_pointer()
func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _test_level_up() -> void:
	if not get_tree().paused:
		$RunState.test_level_up()
func _sync_reward() -> void:
	$Interface/RewardOverlay.refresh()
	get_tree().paused = $Interface/RewardOverlay.visible or $Interface/PauseOverlay.visible
	if not get_tree().paused:
		cursor_released = false
		get_viewport().gui_release_focus()
	_update_pointer()
func _pause_changed() -> void:
	if not get_tree().paused:
		cursor_released = false
	_update_pointer()
func _update_pointer() -> void:
	var locked := get_tree().paused or cursor_released
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if locked else Input.MOUSE_MODE_CAPTURED
	$Player.input_enabled = not locked
	$Interface/Crosshair.visible = not locked
func _unhandled_key_input(event: InputEvent) -> void:
	if not get_tree().paused and not GameData.rebinding_active and event.is_action_pressed("toggle_cursor") and not event.is_echo():
		cursor_released = not cursor_released
		_update_pointer()
		get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and auto_pause_on_focus_loss and is_node_ready():
		if not get_tree().paused and not cursor_released:
			$Interface/PauseOverlay.toggle_pause()
