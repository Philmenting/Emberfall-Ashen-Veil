shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 stone_tint : source_color = vec4(0.37, 0.39, 0.4, 1.0);
uniform float roughness = 0.84;
uniform float dampness : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D grain_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_texture : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_pos;
varying vec3 world_normal;

float grain(vec3 p, vec3 weights) {
 return dot(vec3(texture(grain_texture, p.yz).r,
                 texture(grain_texture, p.xz).r,
                 texture(grain_texture, p.xy).r), weights);
}
void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
 vec3 weights = pow(abs(world_normal), vec3(4.0));
 weights /= max(dot(weights, vec3(1.0)), 0.001);
 float broad = grain(world_pos * 0.031, weights);
 float chisel = grain(world_pos * 0.23, weights);
 float pores = grain(world_pos * 0.77, weights);
 vec3 mineral = texture(stone_texture, world_pos.yz * 0.65).rgb * weights.x
              + texture(stone_texture, world_pos.xz * 0.65).rgb * weights.y
              + texture(stone_texture, world_pos.xy * 0.65).rgb * weights.z;
 float texture_height = dot(mineral, vec3(0.2126, 0.7152, 0.0722));
 float seam = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
 float rim = 1.0 - smoothstep(0.008, 0.055, seam);
 float wet = smoothstep(0.48, 0.72, broad) * dampness;
 vec3 base = stone_tint.rgb * (0.70 + broad * 0.25 + mineral * 0.82);
 base = mix(base, stone_tint.rgb * vec3(0.45, 0.52, 0.44), smoothstep(0.62, 0.80, broad) * 0.35);
 ALBEDO = base * (1.0 - wet * 0.28) + stone_tint.rgb * rim * 0.065;
 float height = chisel * 0.017 + texture_height * 0.026 + pores * 0.004;
 vec3 dx = dFdx(VERTEX);
 vec3 dy = dFdy(VERTEX);
 vec3 tangent = cross(dy, NORMAL);
 vec3 bitangent = cross(NORMAL, dx);
 float determinant = dot(dx, tangent);
 vec3 gradient = sign(determinant) * (dFdx(height) * tangent + dFdy(height) * bitangent);
 NORMAL = normalize(abs(determinant) * NORMAL - gradient);
 ROUGHNESS = clamp(roughness + (chisel - 0.5) * 0.14 - wet * 0.23, 0.24, 0.98);
 SPECULAR = mix(0.28, 0.48, wet);
 AO = 0.88 + chisel * 0.12;
 AO_LIGHT_AFFECT = 0.25;
}

