shader_type canvas_item;
uniform bool inverse_output = false;
uniform float sobel_strength : hint_range(0.0,1.0) = 1.0;
uniform vec3 edge_color = vec3(1.0,1.0,1.0);

uniform vec2 camera_center;
uniform vec2 visible_world_size;
uniform float collision_distances[720];
uniform bool ultimate = false;
// =========================
// WAVE STATE
// =========================
uniform vec2 wave_impact_world_pos;
uniform float wave_impact_time = -10000.0;
uniform float wave_pause_time = -1.0;
uniform float wave_differential = -1.0;
uniform float wave_speed = 48.0;
uniform float wave_width = 48.0;


// =========================
// LASER STATE
// =========================
uniform vec2 laser_impact_world_pos;
uniform float laser_impact_time = -10000.0;
uniform float laser_pause_time = -1.0;
uniform float laser_differential = -1.0;
uniform float laser_speed = 200.0;     // beam wave speed
uniform float laser_wave_width = 1024.0; // MUCH wider band
uniform int laser_count = 0;
uniform float laser_width = 16.0;
uniform float laser_fade_dist = 128.0;
uniform float laser_rotation = 0.0;           // rotate beam pattern

float lum(vec3 color){
    return dot(color, vec3(0.299, 0.587, 0.114)); // brightness
}
// Gaussian falloff
float g(float r, float sigma) {
    return exp(-(r * r) / (2.0 * sigma * sigma));
}

float compute_elapsed(float start_time, float pause_time, float differential) {

	if (start_time < 0.0)
		return -1.0;

	float start_adj = start_time - 0.8;
	float pause_adj = pause_time - 0.8;

	float elapsed = TIME - start_adj;
	if (elapsed <= 0.0)
		return -1.0;

	if (differential != -1.0 || pause_time != -1.0) {

		if (differential == -1.0)
			elapsed = pause_adj - start_adj;
		else
			elapsed -= differential;
	}

	return elapsed;
}


float laser_fraction(sampler2D text, vec2 uv) {
	// Convert UV → world position
	vec2 world_pos = camera_center + (uv - vec2(0.5)) * visible_world_size;

	if (laser_count <= 0) return 0.0;

	float elapsed = compute_elapsed(
		laser_impact_time,
		laser_pause_time,
		laser_differential
	);

	if (elapsed <= 0.0) return 0.0;

	vec2 delta = world_pos - laser_impact_world_pos;
	float dist = length(delta);

	if (dist <= 0.001) return 1.0;
	
	
	// =====================================
	// GLOBAL RADIAL LIGHT FALLOFF
	// =====================================

	// controls how far full intensity reaches
	float light_falloff_distance = 64.0;

	// 1.0 at origin → 0.0 at falloff distance
	float radial_falloff = clamp(dist / light_falloff_distance, 0.0, 1.0);
	
	

	float best_beam_weight = 0.0;

	float beam_spacing = 360.0 / float(laser_count);

	for (int i = 0; i < 64; i++) {
		if (i >= laser_count) break;

		float beam_angle = laser_rotation + float(i) * beam_spacing;
		float rad = radians(beam_angle);
		vec2 beam_dir = vec2(cos(rad), sin(rad));

		float forward = dot(delta, beam_dir);
		if (forward < 0.0) continue;

		// --- COLLISION CHECK ---
		float angle_deg = degrees(atan(delta.y, delta.x));
		if (angle_deg < 0.0) angle_deg += 360.0;
		float index_float = angle_deg * 2.0;
		int index = clamp(int(index_float), 0, 719);
		float max_dist = collision_distances[index];
		if (dist > max_dist || forward > max_dist) continue;

		// =============================
		// LASER WAVE PROPAGATION
		// =============================
		float beam_radius = elapsed * laser_speed;
		float edge_dist = forward - beam_radius;

		// skip pixels ahead of wave front
		if (edge_dist > 0.0) continue;

		// total beam length including fade
		float total_length = laser_wave_width + laser_fade_dist;

		// skip pixels too far behind
		if (edge_dist < -total_length) continue;

		// distance behind solid beam
		float fade_start = -laser_wave_width;

		// if inside solid part → full intensity
		float wave_band;

		if (edge_dist >= fade_start) {
		    wave_band = 1.0;
		}
		else {
		    // inside fade region
		    float fade_t = (edge_dist - (-total_length)) / (laser_fade_dist);
		    wave_band = clamp(fade_t, 0.0, 1.0);
		}

		// perpendicular thickness
		float perpendicular = abs(delta.x * beam_dir.y - delta.y * beam_dir.x);
		if (perpendicular > laser_width) continue;

		float strip_weight = 1.0 - (perpendicular / laser_width)*(perpendicular / laser_width);
		best_beam_weight = max(best_beam_weight, strip_weight * wave_band);
	}


	return best_beam_weight*radial_falloff;
}

float wave_fraction(sampler2D text, vec2 uv){
	float elapsed = compute_elapsed(
		wave_impact_time,
		wave_pause_time,
		wave_differential
	);

	if (elapsed <= 0.0) return 0.0;
		
	
	
	// Convert UV → world position
	vec2 world_pos = camera_center + (uv - vec2(0.5)) * visible_world_size;

	// Distance from impact in WORLD space
	vec2 delta = world_pos - wave_impact_world_pos; // impact_uv is now world position
	float dist = length(delta);


	// Angle in degrees [0,360)
	float angle = degrees(atan(delta.y, delta.x));
	if (angle < 0.0) {
	    angle += 360.0;
	}

	// Convert to index (assuming 0.5° resolution -> 720 samples)
	float index_float = angle * 2.0;
	int index = clamp(int(index_float), 0, 719);

	float max_dist = collision_distances[index];
	
	float visibility_weight = 1.0;

	// If we're past collision distance, search nearby angles
	if (dist > max_dist && !ultimate) {

	    float best_diff = 99999.0;
	    int search_radius = 6; // how many angle steps to check on each side (6 = 3 degrees)

	    for (int i = -6; i <= 6; i++) {

	        int check_index = int(index_float + float(i)/2.0);

	        // wrap around 0–719
	        if (check_index < 0) check_index += 720;
	        if (check_index >= 720) check_index -= 720;

	        float neighbor_max = collision_distances[check_index];

	        if (dist <= neighbor_max) {
	            best_diff = min(best_diff, abs(float(i)));
	        }
	    }

	    if (best_diff == 99999.0) {
	        return 0.0; // no nearby visible angles
	    }

	    // Convert angle difference into soft falloff
	    float max_angle_span = float(search_radius);
	    visibility_weight = 1.0 - (best_diff / max_angle_span);
	}
	float wave_width2=wave_width;
	if (ultimate)
		wave_width2*=.5;

	// Wave radius
	float wave_radius = elapsed * wave_speed;
	float edge_dist = dist - wave_radius;
	
	if (ultimate && edge_dist < 0.0 && edge_dist > -wave_speed*5.0) {

		float t = clamp(-edge_dist / wave_width2, 0.0, 2.0);

		// 0 → 2 over double width
		return t * visibility_weight;
	}

	if ((edge_dist > 0.0  || edge_dist < -wave_width2)) {
	    return 0.0;
	}

	// Smooth radial band
	// 1.0 at exact wave edge
	// 0.0 outside wave_width
	return smoothstep(1.0, 0.0, clamp(-edge_dist/wave_width,0,1)) * visibility_weight;
}

vec4 sobel(vec4 original_color, bool inverse_out, float mix_strength, sampler2D text, vec2 uv){
	vec2 px = 1.0 / vec2(textureSize(text, 0));
	if (original_color.a <= 0.0){
			return original_color;
		}

	float top_l = lum(texture(text, uv + vec2(-px.x, -px.y)).rgb);
	float top  = lum(texture(text, uv + vec2( 0.0 , -px.y)).rgb);
	float top_r = lum(texture(text, uv + vec2( px.x, -px.y)).rgb);

	float left  = lum(texture(text, uv + vec2(-px.x,  0.0)).rgb);
	float center  = lum(texture(text, uv).rgb);
	float right  = lum(texture(text, uv + vec2( px.x,  0.0)).rgb);

	float bottom_l = lum(texture(text, uv + vec2(-px.x,  px.y)).rgb);
	float bottom  = lum(texture(text, uv + vec2( 0.0 ,  px.y)).rgb);
	float bottom_r = lum(texture(text, uv + vec2( px.x,  px.y)).rgb);

	float gx = (top_r + 2.0*right + bottom_r) - (top_l + 2.0*left + bottom_l);
	float gy = (bottom_l + 2.0*bottom + bottom_r) - (top_l + 2.0*top + top_r);
	float edge = sqrt(gx * gx + gy * gy);
	if(inverse_out){
		return vec4(edge_color*(1.0-edge),1.0);
	}else{
		return vec4(edge_color*edge,1.0);
	}
}



void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	COLOR = original_color;
	float wave_phase = wave_fraction(TEXTURE, UV);
	float laser_phase = laser_fraction(TEXTURE, UV);
	float phase = max(wave_phase,laser_phase);
	
	vec4 sob = sobel(original_color, inverse_output, 1.0, TEXTURE, UV);
	vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
	
	
	if (!ultimate) {
		COLOR = mix(original_color, sob, phase);
	}
	else {
		if (phase <= 1.0) {
			// original → sobel
			COLOR = mix(original_color, sob, phase);
		} else {
			// sobel → black
			float t = phase - 1.0;
			COLOR = mix(sob, black, t);
		}
	}
	}