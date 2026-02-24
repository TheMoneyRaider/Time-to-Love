shader_type canvas_item;

uniform sampler2D hole_mask : filter_nearest;
uniform vec2 hole_center;
uniform vec2 node_offset;
uniform float emerge_height;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy-node_offset;
}

void fragment() {
	vec2 uv = (world_pos - hole_center) / 128.0 + vec2(0.5);
	if (texture(hole_mask, uv).r < 0.5 && world_pos.y >= emerge_height){
		discard;
	}
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);

}