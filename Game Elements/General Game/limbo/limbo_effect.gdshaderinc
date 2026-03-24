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
