shader_type canvas_item;

uniform float amplitude = .25;
uniform float frequency = 3.0;
uniform float speed = 2.0;

uniform float tip_strength = 2.0;

uniform vec2 sway_direction = vec2(1.0, 0.0);

void vertex() {

    float t = UV.x;

    float influence = sin(t * PI);

    float wave1 =
        sin(t * frequency - TIME * speed);

    float wave2 =
        sin(t * frequency * 2.1 - TIME * speed * 1.7);

    float wave = wave1 + wave2 * 0.35;

    vec2 offset =
        normalize(sway_direction)
        * wave
        * amplitude
        * influence;

    VERTEX.xy += vec2(offset.y,offset.x);
}