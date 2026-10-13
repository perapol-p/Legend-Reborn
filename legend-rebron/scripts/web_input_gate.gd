extends Label
var player: CharacterBody3D
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 offset_left = -200
 offset_right = 200
 offset_top = -36
 offset_bottom = 36
 horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 text = "CLICK TO PLAY"
 add_theme_font_size_override("font_size",24)
 add_theme_color_override("font_outline_color",Color.BLACK)
 add_theme_constant_override("outline_size",6)
 hide()
func _process(_delta: float) -> void:
 visible = is_instance_valid(player) and player.input_enabled and not get_tree().paused and not player.run.finished and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
func _input(event: InputEvent) -> void:
 if visible and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  get_viewport().set_input_as_handled()
