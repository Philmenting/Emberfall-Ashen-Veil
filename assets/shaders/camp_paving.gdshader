shader_type spatial;
render_mode diffuse_burley, blend_mix, depth_prepass_alpha;
uniform sampler2D stone_color : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_pos;
void vertex() {
  world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
  vec3 paint = texture(stone_color, world_pos.xz * 0.23).rgb;
  ALBEDO = paint * vec3(0.76, 0.72, 0.66);
  ROUGHNESS = 0.9;
  SPECULAR = 0.15;
  // The distant court joins the painting with atmospheric edges, not a display plinth.
  ALPHA = smoothstep(-7.0, -3.5, world_pos.z)
    * (1.0 - smoothstep(6.0, 10.5, abs(world_pos.x)));
}
