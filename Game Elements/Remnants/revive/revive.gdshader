shader_type canvas_item;

uniform vec4 beam_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.8;
uniform float fade_curve : hint_range(0.5, 4.0) = 1.8;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.15;
varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}
void fragment() {
    vec2 uv = UV;



    // Fade toward top — uv.y 0 = top, 1 = bottom
    // So we want alpha to shrink as uv.y approaches 0
    float vertical_fade = pow(uv.y, fade_curve);

    // Soft horizontal falloff from center so edges aren't hard
    float dist_from_center = abs(uv.x - 0.5) * 2.0; // 0 at center, 1 at edge
    float horizontal_fade = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist_from_center);

    // Pulse: sine wave over time, biased so it never goes fully dark
    float pulse = 1.0 - pulse_strength + pulse_strength * (0.5 + 0.5 * sin(TIME * pulse_speed * TAU));

    // Combine
    float alpha = base_alpha * vertical_fade * horizontal_fade * pulse;

    COLOR = vec4(beam_color.rgb, beam_color.a * alpha*modulate_color.a);
}