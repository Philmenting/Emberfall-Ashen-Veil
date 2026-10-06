shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D painting : source_color, filter_linear, repeat_disable;
uniform vec4 haze_color : source_color = vec4(0.0,0.0,0.0,1.0);
uniform float haze_strength : hint_range(0.0,1.0) = 0.0;
// Distance reduces small contrast while retaining the region's original palette.
uniform float distance_contrast : hint_range(0.0,1.0) = 1.0;
void fragment() {
  vec3 scene=texture(painting,UV).rgb;
  float value=dot(scene,vec3(0.299,0.587,0.114));
  scene=mix(vec3(value),scene,0.85+0.15*distance_contrast);
  scene=mix(haze_color.rgb,scene,distance_contrast);
  ALBEDO = mix(scene,haze_color.rgb,haze_strength);
}
