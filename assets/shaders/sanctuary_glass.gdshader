shader_type spatial;
render_mode cull_disabled;
uniform vec4 glass_tint : source_color = vec4(0.28,0.56,0.61,1.0);
varying vec3 local_pos;
void vertex() { local_pos = VERTEX; }
void fragment() {
 float facets=sin(local_pos.y*9.0+local_pos.x*4.0)*sin(local_pos.x*13.0);
 ALBEDO=glass_tint.rgb*(0.65+facets*0.12);
 EMISSION=glass_tint.rgb*(0.38+facets*0.08);
 ROUGHNESS=0.36;
 METALLIC=0.12;
}
