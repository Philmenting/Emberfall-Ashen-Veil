shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 shaft_color : source_color = vec4(0.55, 0.65, 0.8, 1.0);
void fragment() {
 float spread = mix(0.12, 0.48, UV.y);
 float center = 1.0 - smoothstep(spread * 0.2, spread, abs(UV.x - 0.5));
 float ends = smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.65, 1.0, UV.y));
 float drift = 0.88 + sin(UV.y * 12.0 + TIME * 0.23) * 0.12;
 ALBEDO = shaft_color.rgb;
 ALPHA = center * ends * drift * 0.065;
}
