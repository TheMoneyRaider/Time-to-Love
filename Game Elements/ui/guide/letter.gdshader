shader_type canvas_item;

const int MAX_POINTS = 32;

uniform int point_count = 0;
uniform vec2 points[MAX_POINTS];
uniform vec2 center_point;
uniform vec2 image_size;
uniform float quant_scale = 256.0;
uniform float pixel_shadow = 16.0;
uniform float shade_strength = 0.5; // fraction to darken

bool point_in_polygon(vec2 p, float scale){
	bool inside = false;
	for(int i = 0; i < MAX_POINTS; i++){
		if(i >= point_count) break;

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
	float scalex = quant_scale * image_size.x / image_size.y;
	float scaley = quant_scale;
	return vec2(floor(uv.x*scalex)/scalex, floor(uv.y*scaley)/scaley);
}

varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}

void fragment(){
	vec4 tex = texture(TEXTURE, UV);

	// Quantize UV for cheap “pixelated” shading
	vec2 q_uv = quantized_uv(UV);

	if(point_in_polygon(q_uv, .9)){
		COLOR = tex * modulate_color;
	} else if(point_in_polygon(vec2(q_uv.x,q_uv.y-(pixel_shadow/image_size.y)), .9)){
		COLOR = vec4(tex.rgb * (1.0 - shade_strength), tex.a) * modulate_color;
	} else {
		discard;
	}
}