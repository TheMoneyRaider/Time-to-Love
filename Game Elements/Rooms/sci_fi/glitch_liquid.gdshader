shader_type canvas_item;

uniform float u_speed = .5;

uniform vec4 u_color_low : source_color = vec4(0, 0, 0, 1);
uniform vec4 u_color_mid_red : source_color = vec4(0, 0.337, 0.32, 1.0);
uniform vec4 u_color_high : source_color = vec4(.4745, .98, 0.0, 1.0);
uniform float scale = 24.0;
uniform bool enabled = true;

uniform bool inverse_output = true;
uniform vec3 edge_color = vec3(1.0,1.0,1.0);
uniform int z_order = 0;
uniform float progress : hint_range(0.0, 1.0) = .5;
uniform sampler2D sob_noise;
varying vec2 sob_worldUV;

float lum(vec3 color){
    return dot(color, vec3(0.299, 0.587, 0.114)); // brightness
}

vec4 sobel(vec4 original_color, sampler2D text, vec2 uv){
	vec2 px = 1.0 / vec2(textureSize(text, 0));
	if (original_color.a <= 0.0){
			return original_color;
		}
	float top_l = lum(texture(text, uv + vec2(-px.x, -px.y)).rgb);
	float top  = lum(texture(text, uv + vec2( 0.0 , -px.y)).rgb);
	float top_r = lum(texture(text, uv + vec2( px.x, -px.y)).rgb);

	float left  = lum(texture(text, uv + vec2(-px.x,  0.0)).rgb);
	float center  = lum(texture(text, uv).rgb);
	float right  = lum(texture(text, uv + vec2( px.x,  0.0)).rgb);

	float bottom_l = lum(texture(text, uv + vec2(-px.x,  px.y)).rgb);
	float bottom  = lum(texture(text, uv + vec2( 0.0 ,  px.y)).rgb);
	float bottom_r = lum(texture(text, uv + vec2( px.x,  px.y)).rgb);

	float gx = (top_r + 2.0*right + bottom_r) - (top_l + 2.0*left + bottom_l);
	float gy = (bottom_l + 2.0*bottom + bottom_r) - (top_l + 2.0*top + top_r);
	float edge = sqrt(gx * gx + gy * gy);
	return vec4(edge_color*(1.0-edge),1.0);
}

vec2 band(vec2 tiledUV){
	int z_band =  z_order/10;
	vec2 temp_ans;
	if (z_band == 1)
		temp_ans = tiledUV;
	if (z_band == 1)
		temp_ans = vec2(tiledUV.y,tiledUV.x);
	if (z_band == 2)
		temp_ans = vec2(tiledUV.x,tiledUV.y)/1.5 +.5;
	if (z_band == 3)
		temp_ans = vec2(tiledUV.y,1.0-tiledUV.x)*1.5;
	temp_ans+=vec2(3.0,3.0);
	temp_ans = temp_ans - floor(temp_ans);
	return temp_ans;
}

#define iTime (TIME * u_speed)
#define iResolution 1.0/SCREEN_PIXEL_SIZE

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

float fbm( vec2 p )
{
    float f = 0.0;

    f += 0.500000 * noise( p + iTime ); p = mtx * p * 2.02;
    f += 0.031250 * noise( p ); p = mtx * p * 2.01;
    f += 0.250000 * noise( p ); p = mtx * p * 2.03;
    f += 0.125000 * noise( p ); p = mtx * p * 2.01;
    f += 0.062500 * noise( p ); p = mtx * p * 2.04;
    f += 0.015625 * noise( p + sin(iTime) );

    return f / 0.96875;
}

float pattern( in vec2 p )
{
	return fbm( p + fbm( p + fbm( p ) ) );
}

vec4 colormap(float x) {

    if (x < 0.24) {
        return mix(u_color_low, u_color_mid_red, x / 0.24);
    }
    else {
        return mix(u_color_mid_red, u_color_high, (x - 0.24) / 0.76);
    }
}


varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	sob_worldUV = (MODEL_MATRIX*vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (!enabled){
		COLOR = texture(TEXTURE, UV);

	}else{
	    vec4 col = texture(TEXTURE, UV);

	   	float shade = pattern(floor(world_pos)/scale);

	    vec4 map_col = colormap(shade);


	    // Compute luminance of original texture
	    float lum = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));

		// Scale the colormap color to match original brightness
	    vec3 final_rgb = map_col.rgb * lum;

		COLOR = vec4(final_rgb, col.a*map_col.a);

		vec4 original_color = vec4(final_rgb, col.a*map_col.a);
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

}