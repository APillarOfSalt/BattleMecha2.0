shader_type canvas_item;

uniform sampler2D base_sprite;
uniform ivec2 base_dim = ivec2(7, 3); // Number of horizontal and vertical frames
uniform int base_frame = 0; // Current frame index
uniform vec2 base_size = vec2(48.0, 48.0); // Base sprite frame size
uniform vec2 fx_size = vec2(64.0, 64.0); // Effect sprite frame size

// Function to get alpha from base sprite
float get_alpha_from_base(vec2 uv) {
    // Compute frame position in the base sprite sheet
    float frame_x = float(base_frame % base_dim.x);
    float frame_y = float(base_frame / base_dim.x);
    
    vec2 frame_offset = vec2(frame_x, frame_y) * base_size;
    ivec2 base_tex_size = textureSize(base_sprite, 0);
    
    // Convert UV from the effect sprite to base sprite space (48x48 centered in 64x64)
    vec2 base_uv = (uv * fx_size - vec2(8.0)) / base_size;
    
    // Ensure UV stays within the frame bounds
    if (base_uv.x < 0.0 || base_uv.y < 0.0 || base_uv.x > 1.0 || base_uv.y > 1.0) {
        return 0.0;
    }

    // Sample the base sprite at the correct position
    vec2 tex_uv = (frame_offset + base_uv * base_size) / vec2(base_tex_size);
    return sign(texture(base_sprite, tex_uv).a);
}

void fragment() {
    vec4 effect_color = texture(TEXTURE, UV);
    float base_alpha = get_alpha_from_base(UV);
    
    COLOR = vec4(effect_color.rgb, min(effect_color.a, base_alpha));
}
