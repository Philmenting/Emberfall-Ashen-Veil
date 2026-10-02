shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D region_atlas : source_color, filter_linear, repeat_disable;
uniform int region = 0;
void fragment() {
  vec2 cell = vec2(float(region % 2), float(region / 2));
  // Inset each atlas panel to prevent sampling a neighbouring region at edges.
  vec2 inset = vec2(0.0015,0.0030);
  vec2 sample_uv = cell * 0.5 + inset + UV * (vec2(0.5) - inset * 2.0);
  ALBEDO = texture(region_atlas,sample_uv).rgb;
}
