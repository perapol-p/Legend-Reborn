shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 offset_pixels = vec2(0.0);
void fragment() {
 vec2 uv = SCREEN_UV + offset_pixels*SCREEN_PIXEL_SIZE;
 // Clamp shifted edges instead of revealing empty strips.
 uv = clamp(uv,SCREEN_PIXEL_SIZE*0.5,vec2(1.0)-SCREEN_PIXEL_SIZE*0.5);
 COLOR = texture(screen_texture,uv);
}
