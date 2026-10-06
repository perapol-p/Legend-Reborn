extends "res://scripts/fps_weapon_view.gd"
func _init() -> void:
	idle_animation = &"Bow_idle"
	attack_animation = &"Bow_shoot"
	arm_path = ^"Model/Arm_Rig_001/Skeleton3D"
	is_bow = true
