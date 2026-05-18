shader_type canvas_item;

uniform bool pulse_left = true;
uniform vec4 vignette_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform float pulse_strength = 0.0;


void fragment() {
	vec2 uv = UV;

	vec2 vig_uv = uv * (1.0 - uv.yx);

	// Base vignette mask
	float base = clamp(vig_uv.x * vig_uv.y * 16.0, 0.0, 1.0);

	// Invert so edges are 1 and center is 0
	float vignette = 1.0 - base;

	// Strength control
	// 0.0 = no vignette
	// larger values = stronger vignette
	float intensity = 1.0 - exp(-pulse_strength * vignette);

	COLOR.rgb = vignette_color.rgb;
	COLOR.a = intensity;

	if (pulse_left) {
		COLOR.a *= clamp((0.5 - uv.x) * 2.0, 0.0, 1.0);
	} else {
		COLOR.a *= clamp((uv.x - 0.5) * 2.0, 0.0, 1.0);
	}
}