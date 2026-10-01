shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 danger_color : source_color = vec4(0.95, 0.25, 0.09, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform bool border = false;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Stationary hatching describes the full hazard; brightness describes time.
	float stripe = smoothstep(0.42, 0.52, fract((world_position.x + world_position.z) * 2.2));
	vec3 hot_color = mix(danger_color.rgb, vec3(1.0, 0.77, 0.37), progress * progress);
	ALBEDO = hot_color;
	ALPHA = border ? 0.9 : mix(0.10, 0.26, stripe) + progress * 0.16;
}
