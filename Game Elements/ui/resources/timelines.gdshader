shader_type canvas_item;

uniform float time : hint_range(0, 1000) = 0.0;
uniform int tendril_count : hint_range(1, 100) = 8;
uniform float tendril_thickness : hint_range(1, 200) = 4.0;
uniform float tendril_waviness : hint_range(5, 200) = 40.0;
uniform float tendril_speed : hint_range(0, 10) = 1.5;
uniform vec2 view_offset = vec2(0.5,0.5);
uniform float range_start : hint_range(0, 10) = .5; //0 is down, 1 is up
uniform float range_end : hint_range(0, 10) = 1;

vec3 tendril_color(float t) {
	t = t*t*t;
    t = clamp(t, 0.0, 1.0);
    // Gradient along tendril: center=purple, tip=orange
    return mix(vec3(1.0, 0.5, 0.0), vec3(0.6, 0.0, 1.0), t);
}

void fragment() {
    vec2 uv = FRAGCOORD.xy;
    vec2 size= 1.0 / SCREEN_PIXEL_SIZE;
    vec2 center = size;
	center = vec2(center.x * view_offset.x,center.y * view_offset.y);

    vec3 final_color = vec3(0.0);
    float alpha = 0.0;

    for (int i = 0; i < tendril_count; i++) {
        // Angle for tendril from center
        float angle = 3.14159 * range_start + (range_end-range_start)* float(i) / float(tendril_count - 1) * 3.14159;

        // Tendril tip on screen edge (far from center)
        vec2 tip = center + vec2(sin(angle), cos(angle)) *length(size);

        // Vector from tip → center
        vec2 dir = center - tip;

        // Parametric t along tendril (0=tip, 1=center)
        float t = dot(uv - tip, dir) / dot(dir, dir);
        t = clamp(t, 0.0, 1.0);

        // Undulation perpendicular to tendril
        vec2 perp = vec2(-dir.y, dir.x) / length(dir);
        float offset = sin(t * 10.0 + time * tendril_speed + float(i)) * tendril_waviness;

        // Tendril position for current pixel
        vec2 tendril_pos = tip + dir * t + perp * offset;

        // Distance from pixel to tendril
        float dist = length(uv - tendril_pos);

        // Glow based on distance
        float glow = smoothstep(tendril_thickness, 0.0, dist);

        // Accumulate color
        final_color += tendril_color(t) * glow;
        alpha += glow;
    }

    COLOR = vec4(final_color, clamp(alpha, 0.0, 1.0));
}