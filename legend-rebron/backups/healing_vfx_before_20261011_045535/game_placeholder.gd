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
var healing: Node3D
var hit_feedback: Control
var dash_feedback: Control
var music: AudioStreamPlayer
var stage_id := "grassland"
var practice_ui: Control
var practice_hint: Label
func _enter_tree() -> void:
	_configure_stage()
func _ready() -> void:
	var resume_data: Dictionary = GameData.pending_resume
	GameData.pending_resume = {}
	$RunState.character_name = GameData.selected_character
	if not resume_data.is_empty() and resume_data.get("stage") == stage_id:
		preload("res://scripts/run_save_codec.gd").restore_run(self,resume_data)
	$RunState.player_died.connect(_on_player_died)
	$Player.bind_run($RunState)
	var damage_layer := CanvasLayer.new()
	damage_layer.layer = 5
	add_child(damage_layer)
	damage_feedback = preload("res://scripts/damage_feedback.gd").new()
	damage_feedback.name = "DamageFeedback"
	damage_layer.add_child(damage_feedback)
	damage_feedback.bind_player($Player)
	var dash_layer := CanvasLayer.new()
	dash_layer.layer = 4
	add_child(dash_layer)
	dash_feedback = preload("res://scripts/dash_feedback.gd").new()
	dash_feedback.name = "DashFeedback"
	dash_layer.add_child(dash_feedback)
	dash_feedback.bind_player($Player)
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
	var hit_layer := CanvasLayer.new()
	hit_layer.layer = 6
	add_child(hit_layer)
	hit_feedback = preload("res://scripts/hit_feedback.gd").new()
	hit_feedback.name = "HitFeedback"
	hit_layer.add_child(hit_feedback)
	hit_feedback.bind_combat($Player, $Player/Head/Camera3D/Combat)
	sfx = preload("res://scripts/game_sfx.gd").new()
	sfx.name = "GameSFX"
	add_child(sfx)
	sfx.bind_game($Player, $Player/Head/Camera3D/Combat)
	healing = preload("res://scripts/healing_pickups.gd").new()
	healing.name = "HealingPickups"
	healing.game = self
	add_child(healing)
	music = AudioStreamPlayer.new()
	music.name = "IngameMusic"
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	music.bus = "Music"
	music.volume_db = -14.0
	var track := preload("res://assets/audio/music/ingame.mp3").duplicate() as AudioStreamMP3
	track.loop = true
	track.loop_offset = 0.0
	music.stream = track
	add_child(music)
	music.play()
	command_console = preload("res://scripts/command_console.gd").new()
	command_console.game = self
	$Interface.add_child(command_console)
	command_console.set_process_input(stage_id == "practice")
	if stage_id == "practice":
		var tools_layer := CanvasLayer.new()
		tools_layer.layer = 110
		tools_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(tools_layer)
		practice_ui = preload("res://scripts/practice_tools.gd").new()
		practice_ui.game = self
		tools_layer.add_child(practice_ui)
		practice_hint = Label.new()
		practice_hint.text = "U  PRACTICE TOOLS"
		practice_hint.add_theme_font_size_override("font_size",16)
		practice_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tools_layer.add_child(practice_hint)
		practice_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		practice_hint.offset_left = 40
		practice_hint.offset_top = -204
		practice_hint.offset_right = 350
		practice_hint.offset_bottom = -178
		practice_ui.visibility_changed.connect(func(): practice_hint.visible = not practice_ui.visible and not round_finished)
	if not resume_data.is_empty() and resume_data.get("stage") == stage_id:
		preload("res://scripts/run_save_codec.gd").restore_world(self,resume_data)
	elif stage_id != "practice":
		var error := save_checkpoint()
		if error != OK:
			push_warning("Unable to create run checkpoint: " + str(error))
	if stage_id != "practice" and $Arena.has_method("ensure_actor_clearance"):
		$Arena.ensure_actor_clearance($Player)
		for actor in $MonsterSpawner.monsters:
			if is_instance_valid(actor): $Arena.ensure_actor_clearance(actor)
func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
func _sync_reward() -> void:
	if round_finished:
		$Interface/RewardOverlay.hide()
		get_tree().paused = true
		_update_pointer()
		return
	$Interface/RewardOverlay.refresh()
	get_tree().paused = $Interface/RewardOverlay.visible or $Interface/PauseOverlay.visible or GameData.command_console_active or GameData.practice_ui_active
	if not get_tree().paused:
		cursor_released = false
		get_viewport().gui_release_focus()
	_update_pointer()
func _pause_changed() -> void:
	if GameData.practice_ui_active:
		get_tree().paused = true
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
	if round_finished or stage_id == "practice" or not $MonsterSpawner.completed:
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
	if stage_id != "practice":
		GameData.clear_active_run()
	if is_instance_valid(result_overlay):
		return
	if is_instance_valid(music):
		music.stop()
	if is_instance_valid(practice_ui):
		practice_ui.close_panel()
		practice_ui.set_process_input(false)
		practice_hint.hide()
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









func _configure_stage() -> void:
	stage_id = GameData.selected_stage if GameData.selected_stage in GameData.STAGES else "grassland"
	$MonsterSpawner.sandbox_mode = stage_id == "practice"
	if stage_id == "practice":
		$MonsterSpawner.enabled = false
		return
	var old_arena := $Arena
	remove_child(old_arena)
	old_arena.free()
	var arena = load("res://scenes/" + stage_id + "_arena.tscn").instantiate()
	arena.name = "Arena"
	add_child(arena)
	move_child(arena,0)





func save_checkpoint() -> Error:
	if stage_id == "practice" or round_finished or $RunState.finished:
		return ERR_UNAVAILABLE
	return GameData.save_active_run(preload("res://scripts/run_save_codec.gd").capture(self))
