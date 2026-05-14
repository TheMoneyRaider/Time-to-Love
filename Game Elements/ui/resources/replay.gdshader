shader_type canvas_item;

// Core uniforms
uniform float time        : hint_range(0, 1000) = 0.0;
uniform float intensity   : hint_range(0.0, 1.0) = 1.0;
// NEW: playback speed (1 = normal, 2 = 2x rewind, etc.)
uniform float speed       : hint_range(0.5, 4.0) = 1.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth noise for rolling bands
float smooth_noise(float v) {
    float i = floor(v);
    float f = fract(v);
    return mix(rand(vec2(i, 0.0)), rand(vec2(i + 1.0, 0.0)), smoothstep(0.0, 1.0, f));
}

void fragment() {
    vec2 uv = UV;
    float spd = speed * intensity;

    // --- Rolling band / vertical hold instability (NEW) ---
    float band_y  = fract(uv.y * 3.0 - time * 0.4 * spd);
    float band    = smoothstep(0.0, 0.05, band_y) * smoothstep(0.1, 0.05, band_y);
    uv.x += band * 0.015 * intensity;

    // --- Horizontal tears ---
	float tear_prob = 0.995 - 0.7 * intensity * clamp(time * 0.1, 0.0, 1.0);
	float tear = step(tear_prob, rand(vec2(uv.y * 100.0 + floor(time * 10.0 * spd), 0.0)));

	// NEW: quantize uv.y into coarse blocks, pick a random signed offset per block
	float block_count  = 8.0;                          // fewer = chunkier blocks
	float block_id     = floor(uv.y * block_count);
	float block_seed   = floor(time * 8.0 * spd);
	float block_rand   = rand(vec2(block_id, block_seed));

	// Quantize to one of 5 discrete offset levels: -1, -0.5, 0, 0.5, 1
	float steps        = 5.0;
	float quantized    = (floor(block_rand * steps) / (steps - 1.0)) * 2.0 - 1.0;

	// Old smooth version (removed):
	// uv.x += tear * 0.05 * intensity * sin(uv.y * 60.0);

	// New block version:
	uv.x += tear * 0.05 * intensity * quantized;

    // --- Full-line static burst (NEW) ---
    float line_id   = floor(uv.y * 120.0);
    float line_rand  = rand(vec2(line_id, floor(time * 7.0 * spd)));
    float line_burst = step(0.97, line_rand) * intensity;

    // --- RGB shift (vertical component added) ---
    vec2 shift = vec2(0.008, 0.003) * intensity * spd;
    vec4 color = texture(TEXTURE, uv);
    color.r    = texture(TEXTURE, uv + vec2( shift.x,  shift.y)).r;
    color.g    = texture(TEXTURE, uv + vec2(-shift.x, -shift.y)).g;
    // blue channel left at uv (gives green-cyan fringe look)

    // --- Noise / static ---
    float noise = (rand(uv * 200.0 + time * 5.0 * spd) - 0.5) * 0.12 * intensity;
    color.rgb += vec3(noise);
    color.rgb  = mix(color.rgb, vec3(1.0), line_burst * 0.85);

    // --- Scanlines (NEW) ---
    float scanline = sin(uv.y * 800.0) * 0.5 + 0.5;
    float flicker  = 1.0 - smooth_noise(time * 60.0) * 0.04 * intensity;
    color.rgb     *= mix(1.0, scanline * 0.85 + 0.15, 0.4 * intensity) * flicker;

    // --- Vignette (NEW) ---
    vec2  vig_uv = uv * (1.0 - uv.yx);
    float vig    = pow(vig_uv.x * vig_uv.y * 16.0, 0.3 * intensity);
    color.rgb   *= clamp(vig, 0.0, 1.0);

    COLOR = color;
}