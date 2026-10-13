shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform sampler2D artwork : source_color, filter_linear;
uniform float fade : hint_range(0.0,1.0) = 1.0;
void fragment() {
 vec3 ink = texture(artwork,UV).rgb;
 ALBEDO = ink;
 EMISSION = ink*1.7;
 ALPHA = max(max(ink.r,ink.g),ink.b)*fade;
}
