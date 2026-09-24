extends Node3D
func _ready() -> void:
	$Interface/HUD.bind_combo($Combo)
