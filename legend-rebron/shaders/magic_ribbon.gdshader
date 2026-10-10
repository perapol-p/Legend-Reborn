shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.18,0.65,1.0,1.0);
uniform float opacity = 0.6;
uniform float phase = 0.0;
void fragment() {
 float edge = pow(max(sin(UV.y*3.14159),0.0),0.6);
 float flow = 0.55+0.45*sin(UV.x*40.0-phase*5.0);
 ALBEDO = mix(tint.rgb,vec3(0.7,0.88,1.0),flow*0.55);
 ALPHA = edge*flow*opacity;
}
