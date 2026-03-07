shader_type canvas_item;

const int MAX_POINTS = 32;

uniform int point_count = 0;
uniform vec2 points[MAX_POINTS]; // UV-space polygon vertices
uniform vec2 center_point;
uniform vec2 image_size;
uniform float quant_scale = 256.0;

bool point_in_polygon(vec2 p, float scale){

	bool inside = false;
	for(int i = 0; i < MAX_POINTS; i++){
		if(i >= point_count) break;

		// scale the polygon points around the center
		vec2 pi = (points[i] - center_point) * scale + center_point;
		vec2 pj = (points[(i + point_count - 1) % point_count] - center_point) * scale + center_point;

		bool intersect =
			((pi.y > p.y) != (pj.y > p.y)) &&
			(p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x);

		if(intersect){
			inside = !inside;
		}
	}
	return inside;
}


vec2 quantized_uv(vec2 uv){
	float scalex =quant_scale*image_size.x/image_size.y;
	float scaley =quant_scale;
	return vec2(floor(uv.x*scalex)/scalex,floor(uv.y*scaley)/scaley);
}


void fragment(){
	vec4 tex = texture(TEXTURE, UV);

	if(point_in_polygon(quantized_uv(UV),.90)){
		COLOR = tex;
	}else if(point_in_polygon(quantized_uv(UV),.95)){
		COLOR = vec4(tex.rgb /4.0,tex.a);
	}else{
		discard;

	}
}