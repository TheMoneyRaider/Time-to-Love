shader_type canvas_item;

uniform float blur_size : hint_range(0.0, 20.0) = 6.0;

void fragment() {
    vec2 texel = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
    vec4 sum = vec4(0.0);
    
    for(int x=-2; x<=2; x++){
        for(int y=-2; y<=2; y++){
            sum += texture(TEXTURE, UV + vec2(float(x),float(y)) * texel * (blur_size/10.0));
        }
    }
    COLOR = sum / 25.0;
}