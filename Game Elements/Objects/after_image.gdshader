shader_type canvas_item;

uniform bool shader_mono = false;
// This variable will hold the modulate color
varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}

void fragment() {
	if(shader_mono){
    // Sample the texture
    vec4 tex = texture(TEXTURE, UV);

    // Force RGB to white, but keep alpha from texture
    vec3 white_rgb = vec3(1.0);

    // Multiply by the node's modulate (COLOR) to apply runtime tint/fade
    COLOR = vec4(white_rgb, tex.a) * modulate_color;
	}
}