shader_type canvas_item;

uniform vec4 outline_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(1.0, 5.0) = 2.0;
uniform float outline_opacity : hint_range(0.0, 1.0) = 1.0;

uniform bool grayscale = false;
void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (tex_color.a == 0.0) {
	    float alpha = 0.0;
	    for (float x = -outline_thickness; x <= outline_thickness; x += 1.0) {
	        for (float y = -outline_thickness; y <= outline_thickness; y += 1.0) {
				if (length(vec2(x, y)) > outline_thickness)
					continue;
	            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
	            vec4 neighbor = texture(TEXTURE,  UV + offset);
	            alpha = max(alpha, neighbor.a);
	        }
	    }

	    //draw outline if outline pixel
	    if (alpha > 0.0) {
	        vec4 oc = outline_color;
	        oc.a *= outline_opacity;
	        COLOR = oc;
	    }
	}
	if(grayscale){
		vec4 col = texture(TEXTURE,UV);
		float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		vec3 gray_col = vec3(lum);
		COLOR = vec4(gray_col,col.a);
	}
}