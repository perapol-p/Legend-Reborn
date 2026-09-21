extends CanvasLayer
const UI = preload("res://ui/menus/menu_style.gd")
var session: Node
var overlay: Control
var stage: Control
var content: Control
var dialog: ConfirmationDialog
var confirmation: Callable
var is_open: bool = false
var current_page: String = "pause"
var previous_mouse: int = Input.MOUSE_MODE_CAPTURED
var notice: Label
var hud_was_visible: bool = true
var gui_was_visible: bool = true

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	session = get_parent()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.022, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	stage = Control.new()
	stage.size = Vector2(1280, 720)
	overlay.add_child(stage)
	content = Control.new()
	content.size = stage.size
	stage.add_child(content)
	dialog = ConfirmationDialog.new()
	dialog.min_size = Vector2i(470, 155)
	dialog.ok_button_text = "Save and continue"
	dialog.cancel_button_text = "Cancel"
	dialog.confirmed.connect(func():
		if confirmation.is_valid():
			confirmation.call()
	)
	add_child(dialog)
	overlay.hide()
	get_viewport().size_changed.connect(layout_stage)
	layout_stage()

func layout_stage() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var factor: float = minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (viewport_size - Vector2(1280, 720) * factor) * 0.5

func open_menu() -> void:
	if not is_instance_valid(session.player) or session.transitioning:
		return
	var stats_menu = session.player.get_node("CharacterStatsMenu")
	if stats_menu.opened:
		stats_menu.toggle_menu()
	if not is_open:
		previous_mouse = Input.mouse_mode
		hud_was_visible = stats_menu.hud.visible
		gui_was_visible = session.player.get_node("GUI").visible
	stats_menu.hud.hide()
	session.player.get_node("GUI").hide()
	is_open = true
	session.player.end_sprint()
	session.player.end_guard()
	session.player.sprint_timer.stop()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.show()
	show_pause()

func resume_game() -> void:
	dismiss()
	get_tree().paused = false
	Input.mouse_mode = previous_mouse

func dismiss() -> void:
	if is_open and is_instance_valid(session.player) and not session.player.is_dead:
		session.player.get_node("CharacterStatsMenu").hud.visible = hud_was_visible
		session.player.get_node("GUI").visible = gui_was_visible
	is_open = false
	overlay.hide()
	dialog.hide()

func clear_page(page_name: String) -> void:
	current_page = page_name
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func show_pause() -> void:
	clear_page("pause")
	var title := UI.label("LEGEND REBORN", 25, UI.GOLD, true)
	title.position = Vector2(85, 58)
	content.add_child(title)
	var heading := UI.label("Paused", 60, UI.LIGHT, true)
	heading.position = Vector2(84, 123)
	content.add_child(heading)
	var line := ColorRect.new()
	line.position = Vector2(85, 211)
	line.size = Vector2(385, 1)
	line.color = Color("786b4a")
	content.add_child(line)
	var actions := VBoxContainer.new()
	actions.name = "PauseActions"
	actions.position = Vector2(85, 235)
	actions.size.x = 385
	actions.add_theme_constant_override("separation", 3)
	content.add_child(actions)
	var resume := UI.button("Resume", resume_game, 40)
	resume.name = "Resume"
	actions.add_child(resume)
	var character := UI.button("Character / Stats", show_character, 40)
	character.disabled = session.player.is_dead
	actions.add_child(character)
	var inventory := UI.button("Inventory & Equipment", show_inventory, 40)
	inventory.disabled = session.player.is_dead
	actions.add_child(inventory)
	var save := UI.button("Save Game", save_game, 40)
	save.name = "SaveGame"
	save.disabled = session.player.is_dead
	actions.add_child(save)
	actions.add_child(UI.button("Settings", show_settings, 40))
	actions.add_child(UI.button("Controls", show_controls, 40))
	if get_tree().current_scene.scene_file_path == session.WORLD:
		var home_button := UI.button("Return to Home", confirm_home, 40)
		home_button.disabled = session.player.is_dead
		actions.add_child(home_button)
	actions.add_child(UI.button("Return to Main Menu", func(): confirm_exit(false), 40))
	actions.add_child(UI.button("Quit to Desktop", func(): confirm_exit(true), 40))
	var summary := VBoxContainer.new()
	summary.position = Vector2(755, 264)
	summary.size.x = 365
	summary.add_theme_constant_override("separation", 17)
	content.add_child(summary)
	summary.add_child(UI.label("YOUR JOURNEY", 13, UI.MUTED))
	summary.add_child(UI.label(session.area_name(), 32, UI.GOLD, true))
	var p = session.progression()
	summary.add_child(UI.label("LEVEL %02d    /    %d STAT POINTS" % [p.level, p.points], 15))
	for stat in p.KEYS:
		var suffix: String = "%" if stat == "Spd" else ""
		summary.add_child(UI.label("%-16s  %d%s" % [stat.to_upper(), p.value(stat), suffix], 17, UI.MUTED))
	var hint := UI.label("Time stands still.\nResume when you are ready.", 15, UI.MUTED)
	summary.add_child(hint)
	notice = UI.label("Esc / Start: Resume     •     C: Character", 13, UI.GOLD)
	notice.position = Vector2(85, 642)
	notice.size.x = 1060
	content.add_child(notice)
	UI.focus_later(resume)

func save_game() -> void:
	if session.save_game():
		notice.text = "Journey saved."
	else:
		notice.text = session.last_error

func show_error(message: String) -> void:
	show_pause()
	notice.text = message

func show_character() -> void:
	if session.player.is_dead:
		return
	var stats_menu = session.player.get_node("CharacterStatsMenu")
	overlay.hide()
	if not stats_menu.menu_closed.is_connected(character_closed):
		stats_menu.menu_closed.connect(character_closed)
	stats_menu.toggle_menu()

func character_closed() -> void:
	if is_open:
		overlay.show()
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		show_pause()

func show_settings() -> void:
	clear_page("settings")
	UI.settings_page(content, session, show_pause)

func show_controls() -> void:
	clear_page("controls")
	UI.controls_page(content, show_pause)

func show_inventory() -> void:
	clear_page("inventory")
	var stack := UI.panel(content, "Inventory & Equipment", "Equip an item here, then use it with R during play.")
	var player = session.player
	for system in [player.weapon_system, player.gadget_system]:
		var current: String = system.current_equipment.equipment_info.name
		var stored: String = system.stored_mount_point.get_child(0).equipment_info.name
		var row := HBoxContainer.new()
		stack.add_child(row)
		var label := UI.label("Sword" if current == "Equipable Item" else current, 19, UI.GOLD)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var swap := UI.button("Equip " + ("Sword" if stored == "Equipable Item" else stored), func():
			session.restore_equipment(system, stored)
			show_inventory()
		)
		swap.disabled = player.busy or player.dodging
		row.add_child(swap)
	stack.add_child(HSeparator.new())
	for index in range(player.inventory_system.inventory.size()):
		var item = player.inventory_system.inventory[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		stack.add_child(row)
		var icon := TextureRect.new()
		icon.texture = item.texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(52, 52)
		row.add_child(icon)
		var label := UI.label("%s  × %d" % [item.item_name, item.count], 19)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var equip := UI.button("Equipped" if index == 0 else "Equip", func(): equip_item(index))
		equip.disabled = index == 0 or item.count <= 0 or player.busy
		row.add_child(equip)
	stack.add_child(UI.label("Potions restore health. Fire bombs damage enemies.\nEquipment and item counts are included in your save.", 15, UI.MUTED))
	UI.spacer(stack)
	var back_button := UI.button("Back", show_pause)
	stack.add_child(back_button)
	UI.focus_later(back_button)

func equip_item(index: int) -> void:
	var player = session.player
	if player.busy or index >= player.inventory_system.inventory.size():
		return
	player.inventory_system.change_item(0, index)
	player.current_item = player.inventory_system.current_item
	player.item_change_ended.emit(player.current_item)
	show_inventory()

func confirm_exit(to_desktop: bool) -> void:
	dialog.title = "Quit to Desktop?" if to_desktop else "Return to Main Menu?"
	dialog.dialog_text = "Your progress will be saved before leaving."
	if session.player.is_dead:
		dialog.dialog_text = "Your last saved progress will be preserved."
	dialog.ok_button_text = "Save and Quit" if to_desktop else "Save and Return"
	confirmation = session.quit_game if to_desktop else return_main_menu
	dialog.popup_centered()
	dialog.get_cancel_button().grab_focus()

func return_main_menu() -> void:
	if not session.return_to_menu():
		show_error(session.last_error)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(session.player) or session.transitioning:
		return
	var start_pressed: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if event.is_action_pressed("ui_cancel") or start_pressed:
		if is_open:
			if current_page != "pause":
				show_pause()
			else:
				resume_game()
		else:
			open_menu()
		get_viewport().set_input_as_handled()
	elif is_open and event is InputEventKey and event.pressed and event.physical_keycode == KEY_C:
		show_character()
		get_viewport().set_input_as_handled()

func confirm_home() -> void:
	dialog.title = "Return to Home?"
	dialog.dialog_text = "Your dungeon progress will be saved.\nYou can re-enter through the gate at Home."
	dialog.ok_button_text = "Save and Return Home"
	confirmation = func():
		if not session.return_home():
			show_error(session.last_error)
	dialog.popup_centered()
	dialog.get_cancel_button().grab_focus()