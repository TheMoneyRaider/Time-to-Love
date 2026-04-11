// MIT License. 
// Made by Dylearn
// Adapted from atzuk4451 https://godotshaders.com/shader/flexible-toon-shader-godot-4/

shader_type spatial;

group_uniforms colour;
uniform vec4 albedo1 : source_color = vec4(1.0f);

group_uniforms colour.albedo2;
uniform vec4 albedo2 : source_color = vec4(1.0f);
uniform sampler2D albedo2_noise;
uniform float albedo2_scale : hint_range(0.0, 1.0, 0.001) = 0.005;
uniform float albedo2_threshold : hint_range(0.0, 1.0, 0.001) = 0.604;

group_uniforms colour.albedo3;
uniform vec4 albedo3 : source_color = vec4(1.0f);
uniform sampler2D albedo3_noise;
uniform float albedo3_scale : hint_range(0.0, 0.1, 0.001) = 0.003;
uniform float albedo3_threshold : hint_range(0.0, 1.0, 0.001) = 0.661;

group_uniforms lighting;
uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0f, 2.0f) = 0.0f;
uniform float steepness : hint_range(1.0f, 8.0f) = 1.0f;

group_uniforms mask;
uniform vec2 mask_scale;
uniform vec2 mask_offset;
uniform sampler2D mask_texture: filter_nearest, repeat_disable;
uniform vec2 mask_tex_size;


varying vec3 vertex_pos;
varying vec3 normal;
varying vec3 vertex_world;

// MIT License. 
// Made by Dylearn

global uniform sampler2D cloud_noise; // Noise for cloud simulation
global uniform float cloud_scale; // Scale of cloud noise
global uniform float cloud_world_y; // Worldspace y height at which clouds are simulated to cast shadow from
global uniform float cloud_speed; // Speed of cloud movement
global uniform float cloud_contrast; // Steepness of noise pattern
global uniform float cloud_threshold; // Brightness of noise pattern
global uniform vec2 cloud_direction; // Direction of cloud movement
global uniform vec3 light_direction; // Directional light direction
global uniform float cloud_shadow_min; // Minimum light value clouds can cast
global uniform float cloud_diverge_angle; // Angle at which the two noises split from each other

vec2 rotate_vec2(vec2 vector, float angle) {
	float angle_deg = angle * (PI / 180.0);
	float rotated_x  = (vector.x * cos(angle_deg)) - (vector.y * sin(angle_deg));
	float rotated_y  = (vector.x * sin(angle_deg)) + (vector.y * cos(angle_deg));
	return vec2 (rotated_x, rotated_y);
}

float get_cloud_noise(vec3 world_pos) {
	float t = (cloud_world_y - world_pos.y) / light_direction.y;
	vec3 hit_pos = world_pos + t * light_direction;
	float inv_scale = 1.0 / cloud_scale;
	
	//// Non-repeating clouds
	// Rotate wind noise direction left and right
	vec2 cloud_direction1 = rotate_vec2(cloud_direction, cloud_diverge_angle);
	vec2 cloud_direction2 = rotate_vec2(cloud_direction, -cloud_diverge_angle);
	// Scroll noises using time
	vec2 cloud_time_direction1 = TIME * cloud_speed * normalize(cloud_direction1);
	vec2 cloud_time_direction2 = TIME * cloud_speed * normalize(cloud_direction2);
	// Sample noise value (change speed and scale of 2nd one to avoid obvious repeating of texture)
	float cloud_sample1 = texture(cloud_noise, hit_pos.xz * inv_scale + cloud_time_direction1).r;
	float cloud_sample2 = texture(cloud_noise, hit_pos.xz * (inv_scale * 0.8) + (cloud_time_direction2 * 0.89 * PI / 3.0)).r;
	// Combine noise samples
	float cloud_sample = (cloud_sample1 * cloud_sample2);
	float light_value = clamp(cloud_sample + cloud_threshold, 0.0, 1.0);
	
	//// Simple clouds
	//vec2 cloud_offset = cloud_direction * cloud_speed * TIME;
	//vec2 light_uv = (hit_pos.xz * inv_scale) + cloud_offset;
	//float light_value = texture(cloud_noise, light_uv).r;
	
	light_value = (light_value - 0.5) * cloud_contrast + 0.5;
	light_value = clamp(light_value + cloud_threshold, cloud_shadow_min, 1.0);
	return light_value;
}
void vertex() {
	vertex_pos = VERTEX;
	normal = NORMAL;
	vertex_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 mask_uv;

	mask_uv.x = (vertex_world.x / mask_scale.x) / 16.0 - mask_offset.x;
	mask_uv.y = (vertex_world.z / mask_scale.y) / 16.0 - mask_offset.y;
	mask_uv /= mask_tex_size;
	
	float mask = texture(mask_texture, vec2(mask_uv.x,clamp(mask_uv.y-mask_uv.y/50.0,0.0,1.0))).r;
	float mask2 = texture(mask_texture, mask_uv).r;
	if (mask_uv.x<0.0 || mask_uv.x > 1.0 || mask_uv.y<0.0 || mask_uv.y > 1.0){
		mask = 0.0;
		mask2 = 0.0;
	}
	
	if (mask > 0.5 && mask2 < .5) {
		ALBEDO = vec3(0.0,0.0,0.0);
	}else{
		if (mask2 < 0.5) {
			discard;
		}

		// Texture noises for grass patches
		float albedo2_noise_tex = texture(albedo2_noise, vertex_world.xz * (albedo2_scale)).r;
		float albedo3_noise_tex = texture(albedo3_noise, vertex_world.xz * (albedo3_scale)).r;
		// Set colours based on noise thresholds
		ALBEDO = albedo1.rgb;
		if (albedo2_noise_tex > albedo2_threshold) {
			ALBEDO = albedo2.rgb;
		} if (albedo3_noise_tex > albedo3_threshold) {
			ALBEDO = albedo3.rgb;
		}
	}


	
}
	
	
	


void light() {
	// Diffuse lighting.
	float NdotL = dot(NORMAL, LIGHT);
	float diffuse_amount = NdotL + (ATTENUATION - 1.0) + wrap;
	diffuse_amount *= steepness;

	// CLOUDS
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 vertex_world_pos = (MODEL_MATRIX * vec4(vertex_pos, 1.0)).xyz;
		float light_value = get_cloud_noise(vertex_world_pos);
		diffuse_amount = min(diffuse_amount, light_value);
	}

	// Toon Shading
	float cuts_inv = 1.0f / float(cuts);
	float cut = cuts_inv; // single cut width
	float original_index = ceil(diffuse_amount * float(cuts));   // ceil(diffuse * cuts)
	float original_stepped = clamp(original_index * cut, 0.0, 1.0);
	float diffuse_stepped = clamp(diffuse_amount + mod(1.0f - diffuse_amount, cuts_inv), 0.0f, 1.0f);

	diffuse_stepped = original_stepped;
	vec3 diffuse = ALBEDO.rgb * LIGHT_COLOR / PI;
	diffuse *= diffuse_stepped;
	DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
}