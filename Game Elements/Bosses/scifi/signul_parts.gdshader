shader_type canvas_item;
uniform int phase = 0;
uniform sampler2D p1 : source_color;
uniform sampler2D p2 : source_color;
uniform sampler2D p3 : source_color;
uniform float time_offset = 0.0;


uniform int frame = 0;
uniform float blend_width = 0.0125; // range of the blend in SCREEN_UV units (0.0–1.0)

varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}


void fragment() {

	// Calculate frame size
	vec2 frame_size = vec2(1.0 / 8.0, 1.0 / 8.0);

	// Convert frame index to (x,y)
	int fx = frame % 8;
	int fy = frame / 8;

	// Build UV inside the sprite sheet
	vec2 uv = UV;
	uv += vec2(float(fx), float(fy));

    // Map UV to texel center for nearest sampling
    vec2 tex_size = vec2(textureSize(p1, 0)); // use p1, assuming all sheets same size
    uv = uv * tex_size - 0.5;
    ivec2 texel = ivec2(floor(uv + 0.5));
    
    vec4 col;
    if (phase == 0 || phase == 1) {
        col = texelFetch(p1, texel, 0);
    } else if (phase == 2) {
        float progress = clamp((TIME - time_offset) / 2.0, 0.0, 1.0);

        if (TIME >= time_offset + 2.0) {
            col = texelFetch(p2, texel, 0);
        } else {
            // soft blending
            float blend = clamp((SCREEN_UV.y - progress) / blend_width, 0.0, 1.0);
            vec4 c1 = texelFetch(p1, texel, 0);
            vec4 c2 = texelFetch(p2, texel, 0);
            col = mix(c2, c1, blend); // smooth interpolation between p2 -> p1
        }
    } else {
        col = texelFetch(p3, texel, 0);
    }

    COLOR = col * modulate_color;
}
