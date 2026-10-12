shader_type canvas_item;
uniform float strength : hint_range(0.0, 0.3) = 0.0;
void fragment() {
 vec2 edge = abs(UV * 2.0 - 1.0);
 float border = smoothstep(0.68, 1.0, max(edge.x, edge.y));
 COLOR = vec4(0.15, 0.86, 0.37, border * strength);
}
