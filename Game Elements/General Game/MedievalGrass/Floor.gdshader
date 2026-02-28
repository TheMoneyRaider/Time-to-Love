// MIT License.
// Adapted for Sprite2D / canvas_item

shader_type canvas_item;

uniform vec4 albedo1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 albedo2 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo2_noise;
uniform float albedo2_scale : hint_range(0.0, 1.0, 0.001) = 0.005;
uniform float albedo2_threshold : hint_range(0.0, 1.0, 0.001) = 0.604;

uniform vec4 albedo3 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo3_noise;
uniform float albedo3_scale : hint_range(0.0, 0.1, 0.001) = 0.003;
uniform float albedo3_threshold : hint_range(0.0, 1.0, 0.001) = 0.661;

uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0, 2.0) = 0.0;
uniform float steepness : hint_range(1.0, 8.0) = 1.0;

// Optional: light direction for 2D "toon shading"
uniform vec2 light_dir = vec2(0.0, -1.0); 

#include "res://Game Elements/General Game/MedievalGrass/clouds.gdshaderinc"

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
    // Sample noise textures based on UV coordinates
	vec2 p2 = fract((world_pos/16.0) * albedo2_scale); // wraps to 0..1
	vec2 p3 = fract((world_pos/16.0) * albedo3_scale); // wraps to 0..1
    float n2 = texture(albedo2_noise, p2).r;
    float n3 = texture(albedo3_noise, p3).r;

    // Choose base color
    vec3 color = albedo1.rgb;
    if (n2 > albedo2_threshold) {
        color = albedo2.rgb;
    }
    if (n3 > albedo3_threshold) {
        color = albedo3.rgb;
    }

    // Simple 2D "toon" shading using light_dir
    float NdotL = clamp(dot(normalize(vec2(0.0, -1.0)), normalize(light_dir)), 0.0, 1.0);
    NdotL += wrap;
    NdotL = pow(NdotL, steepness);

    float cut_width = 1.0 / float(cuts);
    float step_value = ceil(NdotL * float(cuts)) * cut_width;
    color *= step_value;

    COLOR = vec4(color, 1.0);
}