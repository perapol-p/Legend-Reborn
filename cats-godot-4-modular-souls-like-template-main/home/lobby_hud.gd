extends CanvasLayer
const UI = preload("res://ui/menus/menu_style.gd")
var lobby: Node3D
var prompt: Label
var status: Label
var heading: Label

func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	heading = UI.label("ASHEN REFUGE", 30, UI.GOLD, true)
	heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	heading.position = Vector2(-370, 28)
	heading.size.x = 340
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(heading)
	var subtitle := UI.label("HOME  /  SAFE HAVEN", 13, UI.MUTED)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	subtitle.position = Vector2(-370, 69)
	subtitle.size.x = 340
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(subtitle)
	var footer := PanelContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -108
	footer.offset_left = 125
	footer.add_theme_stylebox_override("panel", UI.style(Color(0.02, 0.03, 0.04, 0.93), Color("77694c")))
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(footer)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	footer.add_child(stack)
	prompt = UI.label("Walk to the dungeon gate", 22, UI.GOLD, true)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(prompt)
	status = UI.label("", 13, UI.MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(status)
	var instructions := UI.label("WASD  Move     /     E  Enter near gate     /     C  Character     /     Esc  Pause", 13, UI.MUTED)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(instructions)

func _process(_delta: float) -> void:
	var session = get_node("/root/GameSession")
	visible = not get_tree().paused and not session.transitioning
	if not visible or not is_instance_valid(lobby.player):
		return
	if lobby.near_gate():
		prompt.text = "[ E ]  Enter Dungeon  -  New Random Expedition"
	else:
		prompt.text = "Walk to the dungeon gate"
	status.text = "Quest Board: Coming soon     /     Merchant: Coming soon"
	if not session.last_error.is_empty():
		status.text = session.last_error
