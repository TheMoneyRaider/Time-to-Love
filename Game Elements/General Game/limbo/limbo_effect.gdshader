shader_type canvas_item;



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


varying vec4 modulate_color;

void vertex() {
	sob_worldUV = (MODEL_MATRIX*vec4(VERTEX, 0.0, 1.0)).xy;
	modulate_color = COLOR;
}

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	COLOR = original_color*modulate_color;
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
