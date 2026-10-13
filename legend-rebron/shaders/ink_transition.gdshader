shader_type canvas_item;
render_mode unshaded;
uniform vec4 base_color : source_color = vec4(0.812,0.38,0.584,1.0);
uniform vec2 node_resolution = vec2(1280.0,720.0);
uniform float factor : hint_range(0.0,1.0) = 0.0;
float hash(vec2 p) {
 return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
void fragment() {
 vec2 p = (UV-vec2(0.5))*node_resolution;
 float maximum = length(node_resolution*0.5);
 float radius = max(1.0,maximum*1.32*factor);
 vec2 q = p/radius;
 float distance = length(q);
 float angle = atan(q.y,q.x);
 // Fixed angular ripples produce lobes, narrow spikes and scalloped edges.
 float rim = 0.88 + 0.075*sin(angle*11.0+0.4)
                  + 0.060*sin(angle*19.0-1.7)
                  + 0.038*sin(angle*31.0+2.1);
 float feather = max(fwidth(distance)*1.2,0.002);
 float ink = 1.0-smoothstep(rim-feather,rim+feather,distance);
 // Round gaps are concentrated around the rim, leaving a solid ink centre.
 vec2 cell = floor(q*12.0);
 vec2 centre = (cell+vec2(0.45+hash(cell)*0.10,0.45+hash(cell+7.0)*0.10))/12.0;
 float hole_radius = mix(0.008,0.035,hash(cell+23.0));
 float hole = 1.0-smoothstep(hole_radius-feather,hole_radius+feather,length(q-centre));
 hole *= step(0.60,hash(cell+49.0))*smoothstep(0.30,0.66,length(centre));
 hole *= 1.0-smoothstep(0.72,0.96,factor);
 ink *= 1.0-hole;
 // Separate little drops beyond the main splash.
 float drop_radius = mix(0.004,0.013,hash(cell+67.0));
 float drop = 1.0-smoothstep(drop_radius-feather,drop_radius+feather,length(q-centre));
 drop *= step(0.91,hash(cell+89.0))*step(rim+0.04,distance)*step(distance,1.13);
 ink = max(ink,drop*(1.0-smoothstep(0.72,0.96,factor)));
 // Every corner is concealed before changing the underlying scene.
 ink = mix(ink,1.0,smoothstep(0.88,1.0,factor));
 if (factor <= 0.0) ink = 0.0;
 if (factor >= 1.0) ink = 1.0;
 COLOR = vec4(base_color.rgb,ink*base_color.a);
}
