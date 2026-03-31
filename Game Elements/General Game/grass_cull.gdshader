shader_type canvas_item;

#include "res://Game Elements/General Game/limbo/limbo_effect.gdshaderinc"


void vertex() {
	sob_worldUV = (MODEL_MATRIX*vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE,UV);
	if(tex.rgb == vec3(0.0,0.0,0.0)){
		discard;
	}
	vec4 original_color = texture(TEXTURE, UV);
	COLOR = original_color;
    if (original_color.a < 0.01) discard;
	vec2 tiledUV = band(fract(floor(sob_worldUV) / 1024.0));
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
