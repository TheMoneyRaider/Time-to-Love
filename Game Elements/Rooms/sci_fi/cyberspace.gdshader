shader_type canvas_item;

uniform float time_speed : hint_range(0.0, 5.0) = 1.0;

const vec3 ro = vec3(0.0, 0.0, 0.0);
const vec2 interval = vec2(3.0, 1.7);

// --- Hash and noise functions ---
float hash1D(float p) {
    return fract(sin(p) * 6124.7621);
}

vec2 hash21(float p) {
    return fract(sin(vec2(p, p*1.4217)) * 6124.7621);
}

float hash2D(vec2 p) {
    vec2 v = vec2(162.1732, 116.1734);
    return fract(sin(dot(p, v)) * 6124.7621);
}

float hash3D(vec3 p) {
    vec3 v = vec3(123.4116, 162.3271, 137.1618);
    return fract(sin(dot(p, v)) * 6124.7621);
}
float noise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0 - 2.0*f);
    vec3 b = vec3(156.0, 12.0, 5.0);
    float n = dot(i, b);
    return mix(
        mix(
            mix(hash1D(n), hash1D(n + b.x), f.x),
            mix(hash1D(n + b.y), hash1D(n + b.x + b.y), f.x),
            f.y
        ),
        mix(
            mix(hash1D(n + b.z), hash1D(n + b.x + b.z), f.x),
            mix(hash1D(n + b.y + b.z), hash1D(n + b.x + b.y + b.z), f.x),
            f.y
        ),
        f.z
    );
}

// --- Seven segment numbers ---
float sevenSegNum(vec2 p, int N) {
    const vec2 segScale = vec2(0.12, 0.45) * 0.9;
    const float a = sqrt(2.0) * 0.5;
    int char = int[](0xEE, 0xA0, 0xD6, 0xF4, 0xB8, 0x7C, 0x7E, 0xE0, 0xFE, 0xFC)[N];

    p.x += a * 3.0;
    p = vec2(p.x - p.y, p.x + p.y) * a;
    ivec2 i = ivec2(floor(p));
    int shift = i.x + 3 * i.y;
    int musk = 1 << shift;
    bool on = (char & musk) > 0;
    on = on && (0 <= i.x && i.x <= 2);

    p = fract(p) - 0.5;
    p.y *= 1.0 - float((0xAB & musk) > 0) * 2.0;

    float d = abs(p.x - p.y) * a - segScale.x;
    p = abs(p);
    d = max(d, max(p.x, p.y) - segScale.y);
    return step(abs(d), 0.07) * float(on);
}

void fragment() {
    vec2 uv = (FRAGCOORD.xy * 2.0 - vec2(SCREEN_PIXEL_SIZE.xy)) / min(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
    vec3 col = vec3(0.0);

    vec3 rd = normalize(vec3(uv, -2.0));
    float t_time = TIME * time_speed;

    for (float i = 0.0; i < 20.0; i += 1.0) {
	    float L = 1.0 - fract(t_time) + i;
	    float t = -L / rd.z;
	    vec2 q = (ro.xy + t * rd.xy) * 4.0;

	    L = dot(q, q) * 2.0 + L * L;
	    float I = ceil(t_time) + i;
	    q += hash21(I) * interval;

	    vec2 q_div = ceil(q / interval);   // Split vec2
	    vec3 ID = vec3(q_div.x, q_div.y, I); // Construct properly

	    q = mod(q, interval) - interval * 0.5;
	    float n = hash3D(ID + ceil(t_time * 3.0) * 1.3834);
	    ID.y += ceil(t_time * 10.0 + hash2D(vec2(ID.x, I)));
	    float n2 = noise3D(ID * 0.316572);

	    float temp = col.g;
	    float d = sevenSegNum(q * 2.35, int(n * 10.0));
	    if (d > 0.0 && n2 < 0.5) {
	        col += float(temp == 0.0) * d * vec3(0.3, 1.0, 0.4) * exp(-L * 0.002);
	        col += step(temp, 0.7) * pow(hash1D(n2), 32.0);
	    }
	}

    COLOR = vec4(col, 1.0);
}