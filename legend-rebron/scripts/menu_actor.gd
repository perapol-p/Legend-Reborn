extends CharacterBody3D
var arena: Node3D
var actor_kind := "zombie"
var route: Array[Vector3] = []
var route_index := 0
var speed := 1.1
var stuck_time := 0.0
var visual: Node3D
var age := 0.0
func _ready() -> void:
 collision_layer = 0
 collision_mask = 1
 floor_snap_length = 0.4
 var collision := CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.radius = 1.2 if actor_kind == "golem" else 0.32
 shape.height = 3.8 if actor_kind == "golem" else 1.8
 collision.shape = shape
 collision.position.y = shape.height*0.5
 add_child(collision)
 match actor_kind:
  "archer": visual = preload("res://scripts/skeleton_archer_visual.gd").new()
  "flyer":
   visual = preload("res://scripts/flying_eye_visual.gd").new()
   motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
  "golem":
   visual = preload("res://scripts/golem_visual.gd").new()
   visual.scale = Vector3.ONE*2.0
  _: visual = preload("res://scripts/zombie_visual.gd").new()
 add_child(visual)
 _update_animation()
func _update_animation() -> void:
 if visual.has_method("update_locomotion"):
  visual.update_locomotion(true,maxf(speed,1.6) if actor_kind == "zombie" else speed)
func _physics_process(delta: float) -> void:
 if route.is_empty(): return
 age += delta
 var offset := route[route_index]-position
 offset.y = 0.0
 if offset.length() < 0.6 or stuck_time > 3.0:
  route_index = (route_index+1)%route.size()
  stuck_time = 0.0
  offset = route[route_index]-position
  offset.y = 0.0
 var direction := offset.normalized()
 var space := get_world_3d().direct_space_state
 for angle in [0.0,0.7,-0.7,1.2,-1.2]:
  var candidate := direction.rotated(Vector3.UP,angle)
  var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*0.85,global_position+Vector3.UP*0.85+candidate*1.3,1,[get_rid()])
  var hit := space.intersect_ray(query)
  if hit.is_empty() or hit.normal.y > 0.7:
   direction = candidate
   break
 rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.z),1.0-exp(-4.0*delta))
 velocity.x = direction.x*speed
 velocity.z = direction.z*speed
 if actor_kind == "flyer":
  var ground := 0.0
  if arena.has_method("ground_height"): ground = arena.ground_height(position.x,position.z)
  elif position.x >= 16 and position.x <= 36 and absf(position.z) <= 12: ground = 2.0
  velocity.y = clampf((ground+2.2+sin(age*1.6)*0.16-position.y)*3.0,-3.0,3.0)
 else: velocity.y -= 25.0*delta
 var before := global_position
 move_and_slide()
 var moved := global_position-before
 moved.y = 0.0
 stuck_time = stuck_time+delta if moved.length() < delta*0.1 else 0.0
 _update_animation()
