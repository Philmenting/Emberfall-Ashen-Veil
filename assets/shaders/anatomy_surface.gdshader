shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 skin_tint : source_color;
uniform vec4 cloth_tint : source_color;
uniform bool all_skin = false;
uniform bool male_face = false;
uniform sampler2D face_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D skin_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D skin_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D linen_texture : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 anatomical_pos;
void vertex() { anatomical_pos = VERTEX; }
void fragment() {
 float exposed = all_skin ? 1.0 : step(0.5, COLOR.a);
 vec3 detail = texture(skin_texture, UV * 12.0).rgb;
 vec3 fabric = texture(linen_texture, UV * 8.0).rgb;
 ALBEDO = mix(cloth_tint.rgb * (0.80 + fabric * 0.65), skin_tint.rgb * COLOR.rgb * (0.88 + detail * 0.25), exposed);
 float y = anatomical_pos.y - (male_face ? 0.01089 : 0.0);
 float face_v = y < 1.78 ? mix(1.0, 0.75, clamp((y - 1.69) / 0.09, 0.0, 1.0))
              : y < 1.83 ? mix(0.75, 0.55, (y - 1.78) / 0.05)
              : y < 1.87190 ? mix(0.55, 0.28, (y - 1.83) / 0.04190)
              : mix(0.28, 0.0, clamp((y - 1.87190) / 0.15810, 0.0, 1.0));
 vec2 face_uv = vec2(clamp(anatomical_pos.x / 0.16 + 0.5, 0.01, 0.99) * 0.5 + (male_face ? 0.5 : 0.0), face_v);
 vec3 face = texture(face_texture, face_uv).rgb;
 float face_mask = smoothstep(1.68, 1.74, anatomical_pos.y) * (1.0 - smoothstep(-0.075, -0.005, anatomical_pos.z)) * exposed;
 vec3 face_tint = male_face ? skin_tint.rgb / vec3(0.56, 0.44, 0.35) : vec3(1.0);
 ALBEDO = mix(ALBEDO, face * face_tint, face_mask);
 ROUGHNESS = mix(0.92, 0.62, exposed);
 SPECULAR = mix(0.24, 0.38, exposed);
 NORMAL_MAP = texture(skin_normal, UV * 12.0).rgb;
 NORMAL_MAP_DEPTH = exposed * 0.4;
}
