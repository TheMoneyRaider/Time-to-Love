shader_type canvas_item;

uniform bool grayscale = false;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (grayscale){
		float lum =  dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
		COLOR.rgb = vec3(lum);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
