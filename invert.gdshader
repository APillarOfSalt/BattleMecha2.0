shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
void fragment(){
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(1.0 - screen_color.rgb, color.a);
}