shader_type canvas_item;

// Time variable, controls speed of artifacts
uniform float time : hint_range(0,1000) = 0.0;
// Intensity of the rewind effect (0 = none, 1 = full)
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

// Random generator
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment(){
    vec2 uv_mod = UV;

    // --- Horizontal glitches / tears ---
    // Probability of tear depends on intensity and time
    float tear_prob = 0.995 - 0.7 * intensity * clamp(time*0.1, 0.0, 1.0);
    float tear = step(tear_prob, rand(vec2(uv_mod.y*100.0 + floor(time*10.0), 0.0)));

    // Apply horizontal offset
    uv_mod.x += tear * 0.05 * intensity * sin(uv_mod.y * 60.0);

    // --- RGB shift ---
    vec4 color = texture(TEXTURE, uv_mod);
    color.r = texture(TEXTURE, uv_mod + vec2(0.008 * intensity, 0.0)).r;
    color.g = texture(TEXTURE, uv_mod + vec2(-0.008 * intensity, 0.0)).g;

    // --- Noise / static ---
    float noise = (rand(uv_mod * 200.0 + time*5.0) - 0.5) * 0.1 * intensity;
    color.rgb += vec3(noise);

    COLOR = color;
}