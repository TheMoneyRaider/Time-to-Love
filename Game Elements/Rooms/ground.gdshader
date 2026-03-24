shader_type canvas_item;


#include "res://Game Elements/General Game/limbo/limbo_effect.gdshaderinc"

// Noise and decal tileset shader by Big Boy Games (Jesse)

uniform sampler2D noise : repeat_enable, filter_nearest;
uniform sampler2D decal : repeat_enable, filter_nearest;
uniform bool displayDecal = false;
uniform bool is_tile_clamped = false;
varying vec2 worldUV;
uniform vec2 noise_offset = vec2(0.0,0.0);

void vertex() {
	worldUV = (MODEL_MATRIX*vec4(VERTEX, 0.0, 1.0)).xy;
	sob_worldUV = (MODEL_MATRIX*vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec2 world_pos = worldUV+noise_offset;
	vec2 noiseCorrect = vec2(1.0,1.0)/vec2(textureSize(noise, 0));
	vec2 decalCorrect = vec2(1.0,1.0)/vec2(textureSize(decal, 0));
    if (is_tile_clamped) {
		// clamp to one value per tile
		world_pos = floor(world_pos / 16.0)*16.0;
	}

	COLOR.rgb = mix(COLOR.rgb, texture(noise, world_pos*noiseCorrect).rgb, texture(noise, world_pos*noiseCorrect).a);

	if (displayDecal) {
		COLOR.rgb = mix(COLOR.rgb, texture(decal, world_pos*decalCorrect).rgb, texture(decal, world_pos*decalCorrect).a * texture(noise, world_pos*noiseCorrect).a);
	}
	
	vec4 original_color = COLOR;
    if (original_color.a < 0.01) discard;
	vec2 tiledUV = fract(floor(sob_worldUV) / 1024.0);
	float value = texture(sob_noise,tiledUV).r;
	if (value < progress){
		vec4 sob = sobel(original_color, TEXTURE, UV);
		COLOR = sob;
	}

    // White border band just ahead of the noise threshold
    if (value >= progress && value < progress + .05) {
        // Fade from white at the edge to transparent toward the unaffected side
        float band = 1.0 - (value - progress) / .05;
        COLOR = mix(original_color, vec4(1.0), band);
    }
}