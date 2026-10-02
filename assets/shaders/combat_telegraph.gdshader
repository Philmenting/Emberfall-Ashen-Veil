shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 danger_color : source_color = vec4(0.95, 0.25, 0.09, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform bool border = false;
uniform bool ink_ground = false;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Stationary hatching describes the full hazard; brightness describes time.
	float stripe = smoothstep(0.42, 0.52, fract((world_position.x + world_position.z) * 2.2));
	vec3 hot_color = mix(danger_color.rgb, vec3(1.0, 0.65, 0.22), progress * progress);
	if (border) {
		// A constant dark outer stroke separates the complete early outline
		// from both sunlit stone and permanent bronze floor ornament.
		ALBEDO = ink_ground ? vec3(0.045,0.018,0.012) : hot_color;
		ALPHA = ink_ground ? 0.97 : 0.98;
	} else {
		ALBEDO = mix(vec3(0.20,0.032,0.008),hot_color,0.55+stripe*0.20);
		ALPHA = mix(0.23,0.36,stripe) + progress * 0.10;
	}
}
