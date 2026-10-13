extends "res://scripts/monster.gd"
var golem_visual: Node3D
func _ready() -> void:
 super._ready()
 add_to_group("bosses")
 for child in model.get_children():
  if child is GeometryInstance3D: child.hide()
 golem_visual = preload("res://scripts/golem_visual.gd").new()
 golem_visual.name = "GolemVisual"
 model.add_child(golem_visual)
 melee_visual = golem_visual
 death_visual = golem_visual
 # Boss root is scaled 2x: capsule is 2.6 m wide and 3.8 m tall in world space.
 var collision := $Collision as CollisionShape3D
 collision.shape = collision.shape.duplicate()
 collision.shape.radius = 0.65
 damage_flash.bind_model(model)
func refresh() -> void:
 health_label.text = "GOLEM  %d / %d" % [ceili(health),ceili(max_health)]
