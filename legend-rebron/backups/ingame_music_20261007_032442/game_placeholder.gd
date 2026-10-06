extends Node3D
@export var auto_pause_on_focus_loss := true
var cursor_released := false
var command_console: PanelContainer
var round_won := false
var round_finished := false
var result_overlay: Control
var victory_overlay: Control
var damage_feedback: Control
var sfx: Node
func _ready() -> void:
	$RunState.character_name = GameData.selected_character
	$RunState.player_died.connect(_on_player_died)
	$Player.bind_run($RunState)
	var damage_layer := CanvasLayer.new()
	damage_layer.layer = 5
	add_child(damage_layer)
	damage_feedback = preload("res://scripts/damage_feedback.gd").new()
	damage_feedback.name = "DamageFeedback"
	damage_layer.add_child(damage_feedback)
	damage_feedback.bind_player($Player)
	$Interface/HUD.bind_combo($Combo)
	$Interface/HUD.bind_run($RunState)
	$Interface/HUD.bind_spawner($MonsterSpawner)
	$MonsterSpawner.round_completed.connect(func(): call_deferred("_show_victory"))
	
	$Interface/PauseOverlay.bind_run($RunState)
	$Interface/PauseOverlay.pause_changed.connect(_pause_changed)
	$Interface/RewardOverlay.bind_run($RunState)
	$RunState.offers_changed.connect(_sync_reward)
	_update_pointer()
	$Player/Head/Camera3D/Combat.bind_combat($Player, $RunState, $Combo)
	$Interface/HUD.bind_combat($Player/Head/Camera3D/Combat)
	sfx = preload("res://scripts/game_sfx.gd").new()
	sfx.name = "GameSFX"
	add_child(sfx)
	sfx.bind_game($Player, $Player/Head/Camera3D/Combat)
	command_console = preload("res://scripts/command_console.gd").new()
	command_console.game = self
	$Interface.add_child(command_console)
func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
func _sync_reward() -> void:
	if round_finished:
		$Interface/RewardOverlay.hide()
		get_tree().paused = true
		_update_pointer()
		return
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
	var locked := get_tree().paused or cursor_released or round_finished
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if locked else Input.MOUSE_MODE_CAPTURED
	$Player.input_enabled = not locked
	$Interface/Crosshair.visible = not locked
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and auto_pause_on_focus_loss and is_node_ready() and not round_finished:
		if not get_tree().paused and not cursor_released:
			$Interface/PauseOverlay.toggle_pause()

func _show_victory() -> void:
	if round_finished or not $MonsterSpawner.completed:
		return
	round_won = true
	round_finished = true
	$RunState.finished = true
	GameData.games_completed += 1
	GameData.save_progress()
	GameData.characters_changed.emit()
	_show_result(true)

func _on_player_died() -> void:
	if round_finished:
		return
	round_finished = true
	get_tree().paused = true
	_update_pointer()
	call_deferred("_show_result", false)

func _show_result(won: bool) -> void:
	if is_instance_valid(result_overlay):
		return
	var summary: Dictionary = $RunState.result_summary()
	if command_console.visible:
		command_console.close_console()
	command_console.set_process_input(false)
	$Interface/PauseOverlay.set_process_input(false)
	$Interface/PauseOverlay.hide()
	$Interface/RewardOverlay.hide()
	$MonsterSpawner.enabled = false
	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var overlay = preload("res://scripts/run_result_overlay.gd").new()
	overlay.summary = summary
	overlay.won = won
	overlay.name = "VictoryOverlay" if won else "GameOverOverlay"
	overlay.retry_requested.connect(func(): _leave_result("res://scenes/game_placeholder.tscn"))
	overlay.main_menu_requested.connect(func(): _leave_result("res://scenes/main_menu.tscn"))
	result_overlay = overlay
	if won:
		victory_overlay = overlay
	layer.add_child(overlay)
	get_tree().paused = true
	_update_pointer()
	$Interface/HUD.refresh_survival()
func _leave_result(scene: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)







