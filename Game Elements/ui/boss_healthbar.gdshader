shader_type canvas_item;

uniform int effect_index = -1;
uniform float progress : hint_range(0.0,1.0)= 1.0;
uniform vec2 image_size = vec2(0, 0);

uniform float P1_u_speed = .125;
uniform vec4 P1_u_color_low : source_color = vec4(0, 0, 0, 1);
uniform vec4 P1_u_color_mid : source_color = vec4(0, 0.396, 0.5607, 1.0);
uniform vec4 P1_u_color_high : source_color = vec4(0, 0.9019, 0.73, 1.0);
uniform float P1_scale = 96.0;

uniform float P2_u_speed = .125;
uniform vec4 P2_u_color_low : source_color = vec4(0, 0, 0, 1);
uniform vec4 P2_u_color_mid : source_color = vec4(0.58, 0.58, 0.58, 1.0);
uniform vec4 P2_u_color_high : source_color = vec4(0.90, 0.90, 0.90, 1.0);
uniform float P2_scale = 32.0;

uniform float P3_u_speed = 1.0;
uniform vec4 P3_u_color_low : source_color = vec4(0, 0, 0, 1);
uniform vec4 P3_u_color_mid : source_color = vec4(0, 0.443, 0.2078, 1.0);
uniform vec4 P3_u_color_high : source_color = vec4(0.329, 0.917, 0.0, 1.0);
uniform float P3_scale = 8.0;




#define P1_iTime (TIME * P1_u_speed)
#define P2_iTime (TIME * P2_u_speed)
#define P3_iTime (TIME * P3_u_speed)

const mat2 mtx = mat2( vec2(0.80, -0.60), vec2(0.60, 0.80) );

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y);

    return res * res;
}

float fbm( vec2 p , float time){
    float f = 0.0;

    f += 0.500000 * noise( p + time ); p = mtx * p * 2.02;
    f += 0.031250 * noise( p ); p = mtx * p * 2.01;
    f += 0.250000 * noise( p ); p = mtx * p * 2.03;
    f += 0.125000 * noise( p ); p = mtx * p * 2.01;
    f += 0.062500 * noise( p ); p = mtx * p * 2.04;
    f += 0.015625 * noise( p + sin(time) );

    return f / 0.96875;
}

float pattern( in vec2 p , float time){
	return fbm( p + fbm( p + fbm( p,time ),time ),time );
}

vec4 colormap(float x, vec4 color_low, vec4 color_mid, vec4 color_high) {

    if (x < 0.24) {
        return mix(P1_u_color_low, color_mid, x / 0.24);
    }
    else {
        return mix(color_mid, color_high, (x - 0.24) / 0.76);
    }
}



bool health_edge(sampler2D text, vec2 uv){
	if (effect_index == -1) {
		if(uv.x > progress)
			return true;
	} else if (effect_index == 0) {
		if(uv.x > progress)
			return true;
	} else if (effect_index == 1) {
		if(uv.x > progress)
			return true;
	} else if (effect_index == 2) {
		if(uv.x > progress)
			return true;
	} else {
	}
	return false;
}




vec4 health_color(sampler2D text, vec2 uv, vec2 pixel_size, vec4 fragment_coord, float time){
	if (effect_index == -1) {
		return texture(text,uv);
	} else if (effect_index == 0) {
		vec2 uv2 = floor(uv*image_size);
		uv2 /= P1_scale;
		return colormap(pattern(uv2,P1_iTime),P1_u_color_low,P1_u_color_mid,P1_u_color_high);
	} else if (effect_index == 1) {
		vec2 uv2 = floor(uv*image_size);
		uv2 /= P2_scale;
		return colormap(pattern(uv2,P2_iTime),P2_u_color_low,P2_u_color_mid,P2_u_color_high);
	} else if (effect_index == 2) {
		vec2 uv2 = floor(uv*image_size);
		uv2 /= P3_scale;
		return colormap(pattern(uv2,P3_iTime),P3_u_color_low,P3_u_color_mid,P3_u_color_high);
	}
	return vec4(0.0,0.0,0.0,0.0);
}
varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}

void fragment() {
	if(health_edge(TEXTURE, UV)){
		discard;
	}
	if (texture(TEXTURE,UV).rgb==vec3(1.0,0.0,0.0)){
		COLOR = vec4(health_color(TEXTURE, UV,SCREEN_PIXEL_SIZE,FRAGCOORD,TIME).rgb,modulate_color.a);
	}else{
		COLOR = texture(TEXTURE,UV);
		COLOR.a *= modulate_color.a;
	}
}
