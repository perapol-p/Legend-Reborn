extends Node
const DURATION := 0.08
var remaining := 0.0
var overlay: ShaderMaterial
func bind_model(model: Node3D) -> void:
 overlay = ShaderMaterial.new()
 overlay.shader = preload("res://shaders/enemy_hit_flash.gdshader")
 for mesh in model.find_children("*", "MeshInstance3D", true, false):
  mesh.material_overlay = overlay
 set_process(false)
func flash() -> void:
 remaining = DURATION
 overlay.set_shader_parameter("strength", 1.0)
 set_process(true)
func _process(delta: float) -> void:
 remaining = maxf(0.0, remaining - delta)
 overlay.set_shader_parameter("strength", remaining / DURATION)
 if remaining <= 0.0:
  set_process(false)