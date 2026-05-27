shader_type canvas_item;

uniform vec4 beam_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.8;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.15;

varying vec4 modulate_color;

void vertex() {
    modulate_color = COLOR;
}

void fragment() {
    vec2 uv = UV;

    float x = (uv.x - 0.5) * 2.0;
    float y = uv.y;

    float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
    float y_corrected = y * aspect * 2.0;

    float dist = sqrt(x * x + y_corrected * y_corrected);

    if (dist > 1.0) discard;

    // Circle edge softness handles ALL lateral shaping — no separate horizontal_fade
    float circle_fade = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);

    // At y=0 (seam), dist == |x| so circle_fade = horizontal softness of the beam
    // This means the seam row fades exactly as the beam's horizontal_fade does
    float vertical_fade = 1.0 - y;

    float pulse = 1.0 - pulse_strength + pulse_strength * (0.5 + 0.5 * sin(TIME * pulse_speed * TAU));

    float alpha = base_alpha * vertical_fade * circle_fade * pulse;

    COLOR = vec4(beam_color.rgb, beam_color.a * alpha * modulate_color.a);
}