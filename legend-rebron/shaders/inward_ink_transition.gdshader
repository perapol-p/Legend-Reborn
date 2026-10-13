shader_type canvas_item;
render_mode unshaded;
uniform vec4 base_color : source_color = vec4(0.0,0.0,0.0,1.0);
uniform vec2 node_resolution = vec2(1280.0,720.0);
uniform float factor : hint_range(0.0,1.0) = 0.0;
float hash(vec2 p) {
 return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
void fragment() {
 float height = max(node_resolution.y,1.0);
 vec2 p = (UV-vec2(0.5))*node_resolution/height;
 float extent = length(node_resolution*0.5)/height;
 float front = mix(extent+0.16,-0.16,factor);
 float angle = atan(p.y,p.x);
 float ripple = 0.018*sin(angle*13.0+0.4)+0.012*sin(angle*23.0-1.7);
 float feather = 1.0/height;
 float ink = smoothstep(front+ripple-feather,front+ripple+feather,length(p));
 // Overlapping round drops grow ahead of the closing edge and merge with it.
 float cell_size = 0.13;
 vec2 cell = floor(p/cell_size);
 for (int y=-1; y<=1; y++) {
  for (int x=-1; x<=1; x++) {
   vec2 id = cell+vec2(float(x),float(y));
   vec2 centre = (id+vec2(0.18+hash(id)*0.64,0.18+hash(id+7.0)*0.64))*cell_size;
   float growth = clamp((length(centre)-front+0.11)/0.20,0.0,1.0);
   float radius = mix(0.014,0.073,hash(id+23.0))*growth;
   float drop = 1.0-smoothstep(radius-feather,radius+feather,length(p-centre));
   ink = max(ink,drop*step(0.001,growth));
  }
 }
 if (factor <= 0.0) ink = 0.0;
 if (factor >= 1.0) ink = 1.0;
 COLOR = vec4(base_color.rgb,ink*base_color.a);
}
