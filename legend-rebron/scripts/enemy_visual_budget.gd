extends Node
var actor: CharacterBody3D
var animations: Array[AnimationPlayer] = []
var accumulated := 0.0
var visibility_timer := 0.0
var visible_model := true
var interval := 1.0/30.0
func _ready() -> void:
 actor = get_parent()
 call_deferred("_configure")
func _configure() -> void:
 if not is_instance_valid(actor): return
 for node in actor.model.find_children("*","AnimationPlayer",true,false):
  node.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  animations.append(node)
func _process(delta: float) -> void:
 if not is_instance_valid(actor) or not is_instance_valid(actor.player): return
 accumulated += delta
 visibility_timer -= delta
 if visibility_timer <= 0.0:
  visibility_timer = 0.15
  var camera: Camera3D = actor.player.get_node("Head/Camera3D")
  var offset: Vector3 = actor.aim_point()-camera.global_position
  var distance: float = offset.length_squared()
  var facing: float = (-camera.global_basis.z).dot(offset.normalized())
  visible_model = actor.dead or distance < 16.0 or facing > -0.15
  actor.model.visible = visible_model
  actor.health_label.visible = not actor.dead and visible_model and distance < 324.0
  var quality: String = preload("res://scripts/performance_profile.gd").quality()
  interval = 0.0 if quality=="high" else (1.0/30.0 if distance < 324.0 or actor.dead else (0.10 if quality=="low" else 1.0/20.0))
 if not visible_model:
  accumulated = 0.0
  return
 if accumulated >= interval:
  for animation in animations:
   if is_instance_valid(animation): animation.advance(accumulated)
  accumulated = 0.0
