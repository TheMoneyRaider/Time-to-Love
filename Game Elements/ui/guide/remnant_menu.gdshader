shader_type canvas_item;
uniform sampler2D gradiant;

void vertex() {
	// Called for every vertex the material is visible on.
}

float cubic_bezier(float t, float p0, float p1, float p2, float p3) {
	float invT = 1.0 - t;
	float invT2 = invT * invT;
	float invT3 = invT2 * invT;
	float t2 = t * t;
	float t3 = t2 * t;

	// The formula
	return invT3 * p0 + 3.0 * invT2 * t * p1 + 3.0 * invT * t2 * p2 + t3 * p3;
}

void fragment() {
	vec4 col = texture(TEXTURE,UV);
	col.a *= texture(gradiant,UV).r;
	COLOR = col;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
