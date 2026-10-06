extends "res://scripts/fps_weapon_view.gd"
@onready var nocked_arrow: MeshInstance3D = $Model/Armature_003/Skeleton3D/Arrow_001
var arrow_released := false
func _init() -> void:
	idle_animation = &"Bow_idle"
	attack_animation = &"Bow_shoot"
func release_arrow() -> void:
	arrow_released = true
	nocked_arrow.hide()
func _process(_delta: float) -> void:
	var combat = get_parent()
	var ready_to_nock: bool = not attacking and (combat.bow_reload <= 0.0 or combat.weapon_level() >= 5)
	if arrow_released and ready_to_nock:
		arrow_released = false
	nocked_arrow.visible = not arrow_released and (combat.bow_ammo > 0 or combat.weapon_level() >= 5)
