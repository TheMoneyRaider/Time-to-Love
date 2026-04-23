shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 fog_color : source_color = vec4(0.8, 0.85, 0.9, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.4;
uniform float fog_height : hint_range(0.0, 1.0) = 0.6; // normalized y cutoff
uniform float fog_softness : hint_range(0.01, 0.5) = 0.2;

void fragment() {
    vec4 screen = texture(screen_texture, SCREEN_UV);
    
    // fog gets thicker toward bottom of screen
    float dist_from_top = SCREEN_UV.y;
    float fog_amount = smoothstep(fog_height - fog_softness, fog_height + fog_softness, dist_from_top);
    fog_amount *= fog_density;
    
    COLOR = mix(screen, fog_color, fog_amount);
}