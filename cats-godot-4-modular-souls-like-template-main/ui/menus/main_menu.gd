extends Control
const UI = preload("res://ui/menus/menu_style.gd")
var session: Node
var stage: Control
var home: Control
var page: Control
var notice: Label
var continue_button: Button
var dialog: ConfirmationDialog
var confirmation: Callable
var background: TextureRect
var elapsed: float = 0.0

func _ready() -> void:
	session = get_node("/root/GameSession")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background = TextureRect.new()
	background.texture = preload("res://ui/menus/art/legend_reborn_background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var darken := ColorRect.new()
	darken.color = Color(0.01, 0.012, 0.008, 0.23)
	darken.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darken.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(darken)
	stage = Control.new()
	stage.size = Vector2(1280, 720)
	add_child(stage)
	home = Control.new()
	home.size = stage.size
	stage.add_child(home)
	var title := UI.label("LEGEND REBORN", 82, UI.GOLD, true)
	title.position = Vector2(0, 222)
	title.size.x = 1280
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 5)
	home.add_child(title)
	var subtitle := UI.label("A S H E S   F A D E .   L E G E N D S   R E T U R N .", 12, Color("afa488"))
	subtitle.position = Vector2(0, 327)
	subtitle.size.x = 1280
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home.add_child(subtitle)
	var options := VBoxContainer.new()
	options.name = "MainActions"
	options.position = Vector2(450, 384)
	options.size.x = 380
	options.add_theme_constant_override("separation", 2)
	home.add_child(options)
	continue_button = UI.button("Continue", continue_game, 37)
	continue_button.name = "Continue"
	continue_button.disabled = not session.has_save()
	options.add_child(continue_button)
	var new_button := UI.button("New Game", new_game, 37)
	new_button.name = "NewGame"
	options.add_child(new_button)
	var load_button := UI.button("Load Game", show_load, 37)
	load_button.name = "LoadGame"
	load_button.disabled = not session.has_save()
	options.add_child(load_button)
	options.add_child(UI.button("Settings", show_settings, 37))
	options.add_child(UI.button("Controls", show_controls, 37))
	options.add_child(UI.button("Quit Game", func(): confirm_action("Quit Legend Reborn?", "Return to your desktop?", session.quit_game), 37))
	notice = UI.label("", 14, UI.GOLD)
	notice.position = Vector2(180, 632)
	notice.size.x = 920
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home.add_child(notice)
	var footer := UI.label("LOCAL ADVENTURE     /     SINGLE PLAYER", 11, Color("858277"))
	footer.position = Vector2(30, 683)
	stage.add_child(footer)
	var version := UI.label("LEGEND REBORN     •     v1.0", 11, Color("858277"))
	version.position = Vector2(1002, 683)
	stage.add_child(version)
	page = Control.new()
	page.size = stage.size
	stage.add_child(page)
	page.hide()
	dialog = ConfirmationDialog.new()
	dialog.title = "Legend Reborn"
	dialog.min_size = Vector2i(460, 150)
	dialog.ok_button_text = "Confirm"
	dialog.cancel_button_text = "Cancel"
	dialog.confirmed.connect(func():
		if confirmation.is_valid():
			confirmation.call()
	)
	add_child(dialog)
	var music := AudioStreamPlayer.new()
	music.name = "MenuMusic"
	music.stream = preload("res://audio/bone_in_the_walls__level_loop_session.ogg")
	music.bus = &"Music"
	music.volume_db = -8
	add_child(music)
	music.play()
	get_viewport().size_changed.connect(layout_stage)
	layout_stage()
	if continue_button.disabled:
		new_button.grab_focus()
	else:
		continue_button.grab_focus()

func layout_stage() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var factor: float = minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (viewport_size - Vector2(1280, 720) * factor) * 0.5

func clear_page() -> void:
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	home.hide()
	page.show()

func back() -> void:
	page.hide()
	home.show()
	if not continue_button.disabled:
		continue_button.grab_focus()
	else:
		home.get_node("MainActions/NewGame").grab_focus()

func show_settings() -> void:
	clear_page()
	UI.settings_page(page, session, back)

func show_controls() -> void:
	clear_page()
	UI.controls_page(page, back)

func show_load() -> void:
	clear_page()
	var stack := UI.panel(page, "Load Game", "One local save slot. Your journey is saved automatically and from Pause.")
	stack.add_child(UI.label(session.save_summary(), 20, UI.GOLD, true))
	stack.add_child(UI.label("Start at Home with your character and equipment.\nRe-enter the gate to resume your saved dungeon.", 16, UI.MUTED))
	UI.spacer(stack)
	var load_button := UI.button("Load this journey", continue_game)
	stack.add_child(load_button)
	stack.add_child(UI.button("Back", back))
	load_button.grab_focus()

func continue_game() -> void:
	notice.text = "Loading your journey..."
	back()
	await get_tree().process_frame
	session.continue_game()
	if not session.transitioning:
		notice.text = session.last_error

func new_game() -> void:
	if session.has_save():
		confirm_action("Start a new journey?", "This replaces the active save and resets your character.\nA backup of the previous save will be kept.", launch_new)
	else:
		launch_new()

func launch_new() -> void:
	notice.text = "Beginning a new legend..."
	await get_tree().process_frame
	session.begin_new_game()
	if not session.transitioning:
		notice.text = session.last_error

func confirm_action(title: String, message: String, action: Callable) -> void:
	confirmation = action
	dialog.title = title
	dialog.dialog_text = message
	dialog.popup_centered()
	dialog.get_cancel_button().grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and page.visible:
		back()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	elapsed += delta
	background.modulate = Color.WHITE * (0.95 + sin(elapsed * 0.22) * 0.05)
