shader_type canvas_item;

uniform float glow_radius : hint_range(0.0, 1.0) = 0.5;

varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}

void fragment() {
    // UV is 0..1 across the texture
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) / glow_radius;

    // radial alpha falloff (soft)
    float alpha = 1.0 - smoothstep(0.0, 1.0, dist);

    COLOR = vec4(modulate_color.rgb, alpha * modulate_color.a);
}