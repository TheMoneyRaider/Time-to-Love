shader_type canvas_item;

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo1 : source_color = vec4(1.0);

uniform vec4 albedo2 : source_color = vec4(1.0);
uniform sampler2D albedo2_noise;
uniform float albedo2_scale : hint_range(0.0, 1.0, 0.001) = 0.005;
uniform float albedo2_threshold : hint_range(0.0, 1.0, 0.001) = 0.604;

uniform vec4 albedo3 : source_color = vec4(1.0);
uniform sampler2D albedo3_noise;
uniform float albedo3_scale : hint_range(0.0, 0.1, 0.001) = 0.003;
uniform float albedo3_threshold : hint_range(0.0, 1.0, 0.001) = 0.661;

uniform sampler2D wind_noise;
uniform float wind_noise_scale = 0.07;
uniform float wind_noise_speed = 0.2;
uniform float world_sway_angle = 0.3;

uniform float view_sway_speed = 1.0;
uniform float view_sway_angle = 0.2;

uniform int character_count = 32;
uniform vec4 character_positions[32]; // xy = pos, w = radius

varying float id_seed1;
varying float id_seed2;
varying float wind_value;
varying float displacement_strength;
varying vec2 world_pos;

float random(float n) {
    return fract(sin(n * 12.9898) * 43758.5453);
}

void vertex() {

    float id = float(INSTANCE_ID);
    id_seed1 = random(id);
    id_seed2 = random(id + 3.14);

    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;

    // WIND
    vec2 noise_uv = world_pos * wind_noise_scale;
    noise_uv += TIME * wind_noise_speed;

    wind_value = texture(wind_noise, noise_uv).r;
    wind_value = (wind_value - 0.5) * 2.0;

    float sway_angle = wind_value * world_sway_angle;
    float view_sway = sin(TIME * view_sway_speed + id) * view_sway_angle;
    float total_sway = sway_angle + view_sway;

    mat2 rot = mat2(
        vec2(cos(total_sway), -sin(total_sway)),
        vec2(sin(total_sway),  cos(total_sway))
    );

    //VERTEX.xy = rot * VERTEX.xy;
	
	vec2 pivot = vec2(0.5, 0.5);

	vec2 centered = VERTEX.xy - pivot;
	centered = rot * centered;
	VERTEX.xy = centered + pivot;

    // CHARACTER DISPLACEMENT
    displacement_strength = 0.0;

    for (int i = 0; i < character_count; i++) {
        vec2 char_pos = character_positions[i].xy;
        float radius = character_positions[i].w;

        float dist = distance(world_pos, char_pos);
        float influence = clamp(1.0 - dist / radius, 0.0, 1.0);
        displacement_strength += influence;
    }

    displacement_strength = clamp(displacement_strength, 0.0, 1.0);
    VERTEX.x += displacement_strength * 5.0 * (1.0 - UV.y);
}

void fragment() {

    vec2 uv = UV;

    vec4 base_tex = texture(albedo_texture, uv);

    // --- WORLD NOISE COLOR PATTERN ---
    vec2 p2 = fract((world_pos / 16.0) * albedo2_scale);
    vec2 p3 = fract((world_pos / 16.0) * albedo3_scale);

    float n2 = texture(albedo2_noise, p2).r;
    float n3 = texture(albedo3_noise, p3).r;

    vec3 pattern_color = albedo1.rgb;

    if (n2 > albedo2_threshold) {
        pattern_color = albedo2.rgb;
    }

    if (n3 > albedo3_threshold) {
        pattern_color = albedo3.rgb;
    }

    vec3 final_color = pattern_color * base_tex.rgb;

    COLOR.rgb = final_color;
    COLOR.a = base_tex.a;

    if (COLOR.a < 0.5) {
        discard;
    }
}