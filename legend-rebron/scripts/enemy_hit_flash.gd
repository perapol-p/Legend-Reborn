extends Node
const DURATION := 0.08
var remaining := 0.0
var overlay: ShaderMaterial
var meshes: Array[GeometryInstance3D] = []
func bind_model(model: Node3D) -> void:
 for mesh in meshes:
  if is_instance_valid(mesh) and mesh.material_overlay == overlay: mesh.material_overlay = null
 meshes.clear()
 overlay = ShaderMaterial.new()
 overlay.shader = preload("res://shaders/enemy_hit_flash.gdshader")
 for mesh in model.find_children("*", "MeshInstance3D", true, false):
  meshes.append(mesh)
 set_process(false)
func flash() -> void:
 remaining = DURATION
 for mesh in meshes:
  if is_instance_valid(mesh): mesh.material_overlay = overlay
 overlay.set_shader_parameter("strength", 1.0)
 set_process(true)
func _process(delta: float) -> void:
 remaining = maxf(0.0, remaining - delta)
 overlay.set_shader_parameter("strength", remaining / DURATION)
 if remaining <= 0.0:
  for mesh in meshes:
   if is_instance_valid(mesh) and mesh.material_overlay == overlay: mesh.material_overlay = null
  set_process(false)