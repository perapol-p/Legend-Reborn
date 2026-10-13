shader_type canvas_item;
void fragment() {
 float left = 1.0-smoothstep(0.12,0.64,UV.x);
 float edge = smoothstep(0.76,1.0,abs(UV.y*2.0-1.0));
 COLOR = vec4(0.025,0.035,0.045,clamp(0.08+left*0.78+edge*0.13,0.0,0.94));
}
