shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 skin_tint : source_color;
uniform vec4 cloth_tint : source_color;
uniform bool all_skin = false;
uniform sampler2D skin_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D skin_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D linen_texture : source_color, filter_linear_mipmap, repeat_enable;
void fragment() {
 float exposed = all_skin ? 1.0 : step(0.5, COLOR.a);
 vec3 detail = texture(skin_texture, UV * 12.0).rgb;
 vec3 fabric = texture(linen_texture, UV * 8.0).rgb;
 ALBEDO = mix(cloth_tint.rgb * (0.80 + fabric * 0.65), skin_tint.rgb * COLOR.rgb * (0.88 + detail * 0.25), exposed);
 ROUGHNESS = mix(0.92, 0.62, exposed);
 SPECULAR = mix(0.24, 0.38, exposed);
 NORMAL_MAP = texture(skin_normal, UV * 12.0).rgb;
 NORMAL_MAP_DEPTH = exposed * 0.4;
}
