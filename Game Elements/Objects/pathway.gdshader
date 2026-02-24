shader_type canvas_item;

uniform bool upper_left = true;
uniform bool split = false;
uniform float x_y_ratio = 1.0;
uniform float band_width = 0.05; // width of the soft diagonal highlight

bool diagonal_mask(vec2 uv) {
    vec2 uv_corr = uv;
    uv_corr.x = uv.x*x_y_ratio;
    uv_corr.y = uv.y;

    return upper_left
        ? (uv_corr.x + uv_corr.y <= 1.0)
        : (uv_corr.x + uv_corr.y > 1.0);
}

void fragment() {
    vec2 uv_corr = UV;
    uv_corr.x *= x_y_ratio;

    // Distance from the diagonal line
    float d = uv_corr.x + uv_corr.y - 1.0;

    // Soft mask: fades from 1 on diagonal to 0 outside the band
    float mask = 1.0 - smoothstep(0.0, band_width, abs(d));

    // Apply hard split discard
    if (split && !diagonal_mask(UV)) {
        discard;
    }

    // Sample texture
    vec4 tex_col = texture(TEXTURE, UV);
	if (split){
	    // Only affect pixels with alpha
	    if (tex_col.a > 0.0) {
	        tex_col.rgb = mix(tex_col.rgb, vec3(1.0), mask);
	    }
	}
    COLOR = tex_col;
}