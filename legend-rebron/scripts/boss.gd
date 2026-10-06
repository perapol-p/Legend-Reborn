extends "res://scripts/monster.gd"
func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("9b253d")
	material.roughness = 0.65
	for mesh in $Model.find_children("*", "MeshInstance3D", true, false):
		if not "Eye" in mesh.name:
			mesh.material_override = material
func refresh() -> void:
	health_label.text = "BOSS  %d / %d" % [ceili(health), ceili(max_health)]
