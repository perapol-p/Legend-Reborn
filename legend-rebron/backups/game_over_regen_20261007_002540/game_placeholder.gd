extends Node3D
@export var auto_pause_on_focus_loss := true
var cursor_released := false
var command_console: PanelContainer
var round_won := false
var victory_overlay: Control
func _ready() -> void:
	$RunState.character_name = GameData.selected_character
	$Player.bind_run($RunState)
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
	command_console = preload("res://scripts/command_console.gd").new()
	command_console.game = self
	$Interface.add_child(command_console)
func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
func _sync_reward() -> void:
	if round_won:
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
	var locked := get_tree().paused or cursor_released or round_won
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if locked else Input.MOUSE_MODE_CAPTURED
	$Player.input_enabled = not locked
	$Interface/Crosshair.visible = not locked
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and auto_pause_on_focus_loss and is_node_ready() and not round_won:
		if not get_tree().paused and not cursor_released:
			$Interface/PauseOverlay.toggle_pause()

func _show_victory() -> void:
	if round_won or not $MonsterSpawner.completed:
		return
	if command_console.visible:
		command_console.close_console()
	round_won = true
	command_console.set_process_input(false)
	get_node("Interface/PauseOverlay").set_process_input(false)
	$Interface/PauseOverlay.hide()
	$Interface/RewardOverlay.hide()
	GameData.games_completed += 1
	GameData.save_progress()
	GameData.characters_changed.emit()
	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	victory_overlay = ColorRect.new()
	victory_overlay.name = "VictoryOverlay"
	victory_overlay.color = Color(0.025, 0.035, 0.045, 0.94)
	layer.add_child(victory_overlay)
	victory_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	victory_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 260)
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui_style.gd").box(Color("171b20"), Color("c6ad72")))
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	var style = preload("res://scripts/ui_style.gd")
	var title := style.label(stack, "VICTORY", 48, style.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var message := style.label(stack, "You survived and defeated the boss!", 20)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var replay := style.button(stack, "PLAY AGAIN", func(): _leave_result("res://scenes/game_placeholder.tscn"))
	style.button(stack, "BACK TO LOBBY", func(): _leave_result("res://scenes/main_menu.tscn"))
	get_tree().paused = true
	_update_pointer()
	replay.grab_focus()
	$Interface/HUD.refresh_survival()

func _leave_result(scene: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)



