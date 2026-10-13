extends ColorRect
var shift := Vector2.ZERO
var shader_material: ShaderMaterial
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shader_material = ShaderMaterial.new()
 shader_material.shader = preload("res://shaders/full_screen_shake.gdshader")
 material = shader_material
 hide()
func set_screen_offset(offset: Vector2) -> void:
 shift = offset
 shader_material.set_shader_parameter("offset_pixels",offset)
 visible = offset.length_squared() > 0.001
