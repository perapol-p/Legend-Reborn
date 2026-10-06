extends SceneTree
func _initialize() -> void:
	print("AMBIENT_COLOR=",Environment.AMBIENT_SOURCE_COLOR)
	print("REFLECT_DISABLED=",ClassDB.class_get_integer_constant("Environment", "REFLECTED_SOURCE_DISABLED"))
	var env := Environment.new()
	for property in env.get_property_list():
		if str(property["name"]) in ["fog_enabled","fog_density","fog_light_color","ambient_light_energy"]:
			print(property["name"],"=",env.get(property["name"]))
	quit()

