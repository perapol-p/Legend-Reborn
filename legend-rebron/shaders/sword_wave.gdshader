shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.25, 0.8, 1.0, 1.0);
uniform float opacity = 1.0;
void fragment() {
	float edge = pow(UV.y, 2.0);
	float taper = pow(sin(UV.x * 3.14159265), 0.45);
	float streak = 0.86 + 0.14 * sin(UV.x * 42.0 - TIME * 22.0);
	ALBEDO = mix(tint.rgb, vec3(0.92, 0.98, 1.0), pow(UV.y, 9.0));
	ALPHA = edge * taper * streak * tint.a * opacity;
}
