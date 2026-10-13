extends RefCounted
static func quality() -> String:
 var data = Engine.get_main_loop().root.get_node_or_null("GameData")
 return data.graphics_quality if data != null else ("low" if OS.has_feature("web") else "medium")
static func particle_count(amount: int) -> int:
 return maxi(4,ceili(amount*(0.35 if quality()=="low" else (0.65 if quality()=="medium" else 1.0))))
static func menu_resolution() -> Vector2i:
 return Vector2i(768,432) if quality()=="low" else (Vector2i(1024,576) if quality()=="medium" else Vector2i(1280,720))
static func prepare_arena(arena: Node3D) -> void:
 # Layer 2 contains scenery only; actors stay on layer 1.
 for body in arena.find_children("*","StaticBody3D",true,false):
  body.collision_layer |= 2
 arena.set_meta("world_collision_mask",2)
 var sun = arena.get_node_or_null("Sun")
 if sun is DirectionalLight3D:
  sun.shadow_enabled = quality() != "low"
  sun.directional_shadow_max_distance = 40.0 if quality()=="medium" else 70.0
