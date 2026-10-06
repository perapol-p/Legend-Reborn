shader_type spatial;
render_mode cull_back;
uniform vec4 base_color : source_color = vec4(0.26,0.31,0.30,1.0);
uniform vec4 alternate_color : source_color = vec4(0.28,0.33,0.32,1.0);
uniform vec4 grid_color : source_color = vec4(0.43,0.49,0.47,1.0);
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 cell = world_position.xz / 4.0;
	vec2 edge = abs(fract(cell - 0.5) - 0.5);
	vec2 aa = max(fwidth(cell),vec2(0.0001));
	vec2 line = 1.0 - smoothstep(vec2(0.012),vec2(0.012) + aa,edge);
	float checker = mod(floor(cell.x) + floor(cell.y),2.0);
	float distance_fade = 1.0 - smoothstep(25.0,65.0,distance(world_position,CAMERA_POSITION_WORLD));
	float resolution_fade = 1.0 - smoothstep(0.12,0.45,max(aa.x,aa.y));
	vec3 color = mix(base_color.rgb,alternate_color.rgb,checker * distance_fade);
	ALBEDO = mix(color,grid_color.rgb,max(line.x,line.y) * distance_fade * resolution_fade * 0.65);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
