extends CharacterBody3D
var arena: Node3D
var route: Array[Vector3] = []
var route_index := 0
var speed := 1.1
var stuck_time := 0.0
var visual: Node3D
func _ready() -> void:
 collision_layer = 0
 collision_mask = 1
 floor_snap_length = 0.4
 var collision := CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.radius = 0.32
 shape.height = 1.8
 collision.shape = shape
 collision.position.y = 0.9
 add_child(collision)
 visual = preload("res://scripts/zombie_visual.gd").new()
 add_child(visual)
 visual.update_locomotion(true,1.8)
func _physics_process(delta: float) -> void:
 if route.is_empty(): return
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
 velocity.y -= 25.0*delta
 var before := global_position
 move_and_slide()
 var moved := global_position-before
 moved.y = 0.0
 stuck_time = stuck_time+delta if moved.length() < delta*0.1 else 0.0
 visual.update_locomotion(true,1.8)
