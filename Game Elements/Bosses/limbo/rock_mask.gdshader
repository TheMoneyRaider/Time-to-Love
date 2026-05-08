shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_white;
uniform vec2 mask_offset = vec2(0.0, 0.0);
uniform vec2 mask_scale = vec2(1.0, 1.0);
varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    // Shift so 0,0 is center, apply offset and scale
    vec2 mask_uv = ((world_pos + mask_offset) / 1300.0) * mask_scale + 0.5;
    float mask = texture(mask_texture, mask_uv).r;
    COLOR = color * COLOR * vec4(1.0, 1.0, 1.0, mask);
}