shader_type canvas_item;

uniform sampler2D mask_texture;
uniform float aberration_strength : hint_range(0.0,0.05) = 0.005;
uniform float mask_intensity : hint_range(0.0,1.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    float mask = texture(mask_texture, uv).a;
    if (mask > 0.0) mask = 1.0;

    // Sample the sprite's own texture
    vec4 base_color = texture(TEXTURE, uv);

    // Chromatic aberration offsets (local UV only)
    vec2 aberr_offset = vec2(aberration_strength, 0.0);

    vec4 aberrated;
    aberrated.r = texture(TEXTURE, uv + aberr_offset).r;
    aberrated.g = base_color.g;
    aberrated.b = texture(TEXTURE, uv - aberr_offset).b;
    aberrated.a = base_color.a;

    // Mix original sprite texture with aberrated color using mask_teture
    vec4 color_with_aberration = mix(base_color, aberrated, mask);

    // Add visible mask if desired
    vec4 mask_color = texture(mask_texture, uv) * mask_intensity;

    COLOR = color_with_aberration + mask_color * mask;
}