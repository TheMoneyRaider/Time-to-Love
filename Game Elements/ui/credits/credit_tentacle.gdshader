shader_type canvas_item;

uniform float amplitude = .5;
uniform float frequency = 3.0;
uniform float speed = 1.0;



// Noise texture
uniform sampler2D noise_texture;

// Controls cutoff amount
uniform int timeline = 0;

varying vec4 modulate_color;

void vertex() {
    modulate_color = COLOR;

    float t = UV.x;

    float influence = sin(t * PI);

    float wave1 =
        sin(t * frequency - TIME * speed);

    float wave2 =
        sin(t * frequency * 2.1 - TIME * speed * 1.7);

    float wave = wave1 + wave2 * 0.35;

    vec2 offset =
        vec2(1.0,0.0)
        * wave
        * amplitude
        * influence;

    VERTEX.xy += vec2(offset.y,offset.x);
}
float lum(vec3 color){
    return dot(color, vec3(0.299, 0.587, 0.114)); // brightness
}
void fragment() {

    vec4 tex = texture(TEXTURE, UV);

    // Sample animated noise

    float noise =
        texture(noise_texture, UV).r;

	float lower = 0.0;
	float higher = 1.0;
	if(timeline==0){
		higher = .35;
	}else if(timeline==1){
		lower=.35;
		higher=.6;
	}else{
		lower = .6;
	}
        COLOR = tex;
    // Cut holes in sprite
    if (noise < lower || noise > higher) {
		COLOR.a = modulate_color.a * tex.a;
		float value = 1.0-lum(tex.rgb);
		COLOR.rgb = vec3(value);
    }else{
	}

}