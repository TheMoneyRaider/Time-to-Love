shader_type canvas_item;

uniform sampler2D mask_texture;
uniform float aberration_strength : hint_range(0.0, 30.0) = 2.0;
uniform float mask_intensity : hint_range(0.0,1.0) = 1.0;
uniform bool grayscale = false;

void fragment() {
    vec2 uv = UV;
    float mask = texture(mask_texture, uv).a;
    if (mask > 0.0) mask = 1.0;

    // Sample the sprite's own texture
    vec4 base_color = texture(TEXTURE, uv);

    // Chromatic aberration offsets (local UV only)
	vec2 aberr_offset = vec2(aberration_strength * TEXTURE_PIXEL_SIZE.x, 0.0);

    vec4 aberrated;
    aberrated.r = texture(TEXTURE, uv + aberr_offset).r;
    aberrated.g = base_color.g;
    aberrated.b = texture(TEXTURE, uv - aberr_offset).b;
    aberrated.a = base_color.a;

    // Mix original sprite texture with aberrated color using mask_teture
    vec4 color_with_aberration = mix(base_color, aberrated, mask);

    // Add visible mask if desired
    vec4 mask_color = texture(mask_texture, uv) * mask_intensity;

	COLOR = mix(color_with_aberration, color_with_aberration + mask_color, mask * mask_intensity);
	if (grayscale){
		float lum =  dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
		COLOR.rgb = vec3(lum);
	}
}