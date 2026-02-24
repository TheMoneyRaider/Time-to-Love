shader_type canvas_item;
uniform bool sobel_enabled = false;
uniform bool inverse_output = false;
uniform float sobel_strength : hint_range(0.0,1.0) = 1.0;
uniform vec3 edge_color = vec3(1.0,1.0,1.0);


void vertex() {
	// Called for every vertex the material is visible on.
}

float lum(vec3 color){
    return dot(color, vec3(0.299, 0.587, 0.114)); // brightness
}
// Simple gaussian falloff
float g(float r, float sigma) {
    return exp(-(r * r) / (2.0 * sigma * sigma));
}


void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	vec2 px = 1.0 / vec2(textureSize(TEXTURE, 0));
	COLOR = original_color;
	if(sobel_enabled){
		if (original_color.a <= 0.0){
			discard;
		}
		
		float top_l = lum(texture(TEXTURE, UV + vec2(-px.x, -px.y)).rgb);
		float top  = lum(texture(TEXTURE, UV + vec2( 0.0 , -px.y)).rgb);
		float top_r = lum(texture(TEXTURE, UV + vec2( px.x, -px.y)).rgb);

		float left  = lum(texture(TEXTURE, UV + vec2(-px.x,  0.0)).rgb);
		float center  = lum(texture(TEXTURE, UV).rgb);
		float right  = lum(texture(TEXTURE, UV + vec2( px.x,  0.0)).rgb);

		float bottom_l = lum(texture(TEXTURE, UV + vec2(-px.x,  px.y)).rgb);
		float bottom  = lum(texture(TEXTURE, UV + vec2( 0.0 ,  px.y)).rgb);
		float bottom_r = lum(texture(TEXTURE, UV + vec2( px.x,  px.y)).rgb);
		
		float gx = (top_r + 2.0*right + bottom_r) - (top_l + 2.0*left + bottom_l);
		float gy = (bottom_l + 2.0*bottom + bottom_r) - (top_l + 2.0*top + top_r);
		float edge = sqrt(gx * gx + gy * gy);
		if(inverse_output){
			COLOR = mix(original_color,vec4(edge_color*(1.0-edge), 1.0),sobel_strength);
		}else{
			COLOR = mix(original_color,vec4(edge_color*edge, 1.0),sobel_strength);
		}
	}
	
	
}