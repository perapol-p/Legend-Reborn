shader_type spatial;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 cell = abs(fract(world_position.xz / 4.0 - 0.5) - 0.5) * 4.0;
	float line = 1.0 - smoothstep(0.025, 0.06, min(cell.x, cell.y));
	ALBEDO = mix(vec3(0.075, 0.095, 0.12), vec3(0.16, 0.22, 0.28), line);
	ROUGHNESS = 0.85;
}
