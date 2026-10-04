shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D painting : source_color, filter_linear, repeat_disable;
uniform vec4 haze_color : source_color = vec4(0.0,0.0,0.0,1.0);
uniform float haze_strength : hint_range(0.0,1.0) = 0.0;
void fragment() {
  ALBEDO = mix(texture(painting,UV).rgb,haze_color.rgb,haze_strength);
}
