shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.18,0.65,1.0,1.0);
uniform float phase = 0.0;
uniform float opacity = 1.0;
varying vec3 local_position;
void vertex() {
 local_position = VERTEX;
 VERTEX += NORMAL * sin(VERTEX.y*13.0+VERTEX.x*8.0+phase*3.0) * 0.015;
}
void fragment() {
 float rim = pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),1.4);
 float field = sin(UV.x*25.1327+UV.y*18.0-phase*4.0);
 float filaments = pow(abs(sin(field*3.0+UV.y*22.0+phase*2.0)),8.0);
 ALBEDO = mix(tint.rgb,vec3(0.73,0.92,1.0),filaments*0.65);
 ALPHA = (0.12+rim*0.5+filaments*0.24)*opacity;
}
