shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D painting : source_color, filter_linear, repeat_disable;
void fragment() {
  ALBEDO = texture(painting,UV).rgb;
}
