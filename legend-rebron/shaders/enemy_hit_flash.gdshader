shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
 ALBEDO = vec3(1.0, 0.96, 0.86);
 ALPHA = strength * 0.8;
}