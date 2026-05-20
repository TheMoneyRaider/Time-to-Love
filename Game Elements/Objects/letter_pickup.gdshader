shader_type canvas_item;

uniform float pulse_speed : hint_range(0.1, 5.0) = 1.5;
uniform float pulse_size : hint_range(0.1, 1.0) = 0.6;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.15;
uniform float fade_min : hint_range(0.0, 1.0) = 0.1;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);

    // Pulse: radius breathes between a small and large value
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    float radius = pulse_size * pulse;

    // Soft circle edge
    float circle = 1.0 - smoothstep(radius - edge_softness, radius + edge_softness, dist);

    // Fade alpha with the pulse so it dims as it shrinks
    float alpha = circle * mix(fade_min, 1.0, pulse);

    COLOR = vec4(glow_color.rgb, alpha * glow_color.a);
}