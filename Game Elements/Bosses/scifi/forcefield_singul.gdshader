shader_type canvas_item;
uniform vec3 color : source_color = vec3(0, 0.678, 0.75);
uniform float cutoff_min = 1.0;
uniform float cutoff_max = 1.0;



varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}

void fragment() {
	if(UV.y > cutoff_min && UV.y < cutoff_max)
		discard;
	COLOR = vec4(color,modulate_color.a*UV.y*UV.y*sqrt((.5-abs(UV.x-.5))));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
