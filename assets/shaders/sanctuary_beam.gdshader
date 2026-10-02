shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 beam_tint : source_color = vec4(0.48,0.68,0.8,0.10);
uniform float motion = 1.0;
void fragment() {
 float edge=pow(max(0.0,1.0-abs(UV.x*2.0-1.0)),2.0);
 float ends=smoothstep(0.0,0.16,UV.y)*(1.0-smoothstep(0.55,1.0,UV.y));
 float dust=0.9+0.1*sin(UV.y*18.0+TIME*0.12*motion);
 ALBEDO=beam_tint.rgb;
 ALPHA=edge*ends*dust*beam_tint.a;
}
