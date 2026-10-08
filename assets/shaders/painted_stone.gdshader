shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D stone_color : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(0.7,0.7,0.7,1.0);
uniform float roughness = 0.86;
uniform float weathering = 0.1;
uniform vec4 mineral_tint : source_color = vec4(0.22,0.26,0.27,1.0);
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
  world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
  world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
  vec3 w=pow(abs(world_normal),vec3(6.0));
  w/=max(w.x+w.y+w.z,0.001);
  vec3 p=world_pos*0.23;
  vec3 paint=texture(stone_color,p.zy).rgb*w.x+texture(stone_color,p.xz).rgb*w.y+texture(stone_color,p.xy).rgb*w.z;
  // Broad painted value changes retain the silhouette without photographic grain.
  ALBEDO=mix(paint*stone_tint.rgb*1.75,mineral_tint.rgb,weathering*0.18);
  ROUGHNESS=roughness;
  SPECULAR=0.18;
}
