shader_type canvas_item;

/* ============ EXISTING PARAMS ============ */
uniform float u_speed = .5;

uniform vec4 u_color_low : source_color = vec4(0, 0, 0, 1);
uniform vec4 u_color_mid_red : source_color = vec4(0, 0.337, 0.32, 1.0);
uniform vec4 u_color_high : source_color = vec4(.4745, .98, 0.0, 1.0);
uniform float scale = 24.0;

/* ============ NEW PARAMS ============ */
/* current target progress (0 → 1) */
uniform float progress : hint_range(0.0, 1.0) = 0.0;

/* how long interpolation takes */
uniform float interp_time = 0.4;

/* when progress last changed (set from script using TIME) */
uniform float time_offset = 0.0;


/* ============ ORIGINAL STUFF ============ */

#define iTime (TIME * u_speed)
#define iResolution 1.0/SCREEN_PIXEL_SIZE

const mat2 mtx = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));

float rand(vec2 n){
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);

    float res = mix(
        mix(rand(ip), rand(ip+vec2(1,0)), u.x),
        mix(rand(ip+vec2(0,1)), rand(ip+vec2(1,1)), u.x), u.y);

    return res*res;
}

float fbm(vec2 p){
    float f = 0.0;

    f += 0.5 * noise(p + iTime); p = mtx*p*2.02;
    f += 0.03125 * noise(p); p = mtx*p*2.01;
    f += 0.25 * noise(p); p = mtx*p*2.03;
    f += 0.125 * noise(p); p = mtx*p*2.01;
    f += 0.0625 * noise(p); p = mtx*p*2.04;
    f += 0.015625 * noise(p + sin(iTime));

    return f / 0.96875;
}

float pattern(in vec2 p){
    return fbm(p + fbm(p + fbm(p)));
}

vec4 colormap(float x){
    if (x < 0.24)
        return mix(u_color_low, u_color_mid_red, x/0.24);
    else
        return mix(u_color_mid_red, u_color_high, (x-0.24)/0.76);
}

varying vec2 world_pos;

void vertex(){
    world_pos = (MODEL_MATRIX * vec4(VERTEX,0,1)).xy;
}


/* ============ MAGIC PART ============ */
uniform float prev_progress = 0.0;
void fragment(){

    vec4 tex = texture(TEXTURE, UV);

    /* ----- ONLY PURE BLACK ----- */
    bool is_black =
        tex.r < 0.001 &&
        tex.g < 0.001 &&
        tex.b < 0.001;

    /* ----- smooth progress interpolation ----- */
    float t = clamp((TIME - time_offset) / interp_time, 0.0, 1.0);

    float current_progress = mix(prev_progress, progress, t);

    /* ----- progress bar mask (left → right) ----- */
    float mask = step(UV.x, current_progress);

    /* ----- if not black or not yet revealed → keep original ----- */
    if (!is_black || mask < 0.5){
    }else{

    /* ----- your glitch shading ----- */
    float shade = pattern(floor(world_pos)/scale);
    vec4 map_col = colormap(shade);

    float lum = dot(tex.rgb, vec3(0.2126,0.7152,0.0722));
    vec3 final_rgb = map_col.rgb * max(lum, 1.0);
	if (current_progress > .8){
		COLOR = mix(vec4(u_color_mid_red.rgb, tex.a * map_col.a),vec4(final_rgb, tex.a * map_col.a),((current_progress-.8)/.2)*((current_progress-.8)/.2));
	}else{
		COLOR = vec4(u_color_mid_red.rgb, tex.a * map_col.a);
	}
	}
}