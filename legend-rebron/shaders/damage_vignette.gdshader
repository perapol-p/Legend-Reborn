shader_type canvas_item;
uniform float flash = 0.0;
uniform float low_health : hint_range(0.0, 1.0) = 0.0;
uniform float direction_strength = 0.0;
uniform vec2 hit_direction = vec2(0.0, 1.0);
void fragment() {
	vec2 offset = UV * 2.0 - 1.0;
	float border = smoothstep(0.60, 1.0, max(abs(offset.x), abs(offset.y)));
	vec2 radial = offset / max(length(offset), 0.001);
	float directional = smoothstep(0.70, 0.98, dot(radial, hit_direction));
	float health_border = smoothstep(0.35, 1.0, max(abs(offset.x), abs(offset.y)));
	float health_alpha = health_border * low_health * 0.50;
	float hit_alpha = border * (flash * 0.22 + directional * direction_strength * 0.48);
	float alpha = health_alpha + hit_alpha * (1.0 - health_alpha);
	COLOR = vec4(0.88, 0.025, 0.035, clamp(alpha, 0.0, 0.72));
}
