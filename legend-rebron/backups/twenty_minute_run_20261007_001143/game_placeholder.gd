extends Node3D
@export var auto_pause_on_focus_loss := true
var cursor_released := false
var command_console: PanelContainer
func _ready() -> void:
	$RunState.character_name = GameData.selected_character
	$Player.bind_run($RunState)
	$Interface/HUD.bind_combo($Combo)
	$Interface/HUD.bind_run($RunState)
	$Interface/HUD.bind_spawner($MonsterSpawner)
	
	$Interface/PauseOverlay.bind_run($RunState)
	$Interface/PauseOverlay.pause_changed.connect(_pause_changed)
	$Interface/RewardOverlay.bind_run($RunState)
	$RunState.offers_changed.connect(_sync_reward)
	_update_pointer()
	$Player/Head/Camera3D/Combat.bind_combat($Player, $RunState, $Combo)
	command_console = preload("res://scripts/command_console.gd").new()
	command_console.game = self
	$Interface.add_child(command_console)
func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _sync_reward() -> void:
	$Interface/RewardOverlay.refresh()
	get_tree().paused = $Interface/RewardOverlay.visible or $Interface/PauseOverlay.visible or GameData.command_console_active
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
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and auto_pause_on_focus_loss and is_node_ready():
		if not get_tree().paused and not cursor_released:
			$Interface/PauseOverlay.toggle_pause()
