shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 tint : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform float metal = 0.0;
uniform float cloth = 0.0;
uniform float surface_type = 0.0;
uniform bool vertex_materials = false;
varying vec3 local_pos;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
void vertex() { local_pos = VERTEX; }
void fragment() {
 vec4 base_tint = vertex_materials ? COLOR : tint;
 float surface_metal = vertex_materials ? UV2.x : metal;
 float type = vertex_materials ? floor(UV2.y / 4.0 + 0.01) : surface_type;
 float glow = vertex_materials ? clamp(UV2.y - type * 4.0, 0.0, 1.0) : 0.0;
 float fabric = (1.0 - step(0.05, surface_metal)) * (1.0 - step(0.5, type)) * (1.0 - step(0.5, glow));
 vec2 threads = UV * vec2(190.0, 145.0);
 vec2 thread_filter = 1.0 - smoothstep(vec2(0.4), vec2(1.5), fwidth(threads));
 float weave = sin(threads.x * 6.28318) * sin(threads.y * 6.28318) * thread_filter.x * thread_filter.y;
 float grain = hash(floor(local_pos * 110.0));
 float scratch_phase = local_pos.y * 95.0 + local_pos.x * 17.0;
 float scratch_filter = 1.0 - smoothstep(0.7, 2.0, fwidth(scratch_phase));
 float scratches = pow(abs(sin(scratch_phase)), 26.0) * scratch_filter;
 float micro_filter = 1.0 - smoothstep(0.005, 0.03, length(fwidth(local_pos)));
 ALBEDO = base_tint.rgb * (0.91 + (grain - 0.5) * 0.10 * micro_filter + weave * 0.055 * fabric + scratches * 0.065 * surface_metal);
 METALLIC = surface_metal;
 float base_roughness = mix(0.88, 0.32, surface_metal);
 if (type > 0.5 && type < 1.5) { base_roughness = 0.63; }
 if (type > 1.5 && type < 2.5) { base_roughness = 0.57; }
 ROUGHNESS = clamp(base_roughness + (grain - 0.5) * 0.08 * micro_filter + length(fwidth(NORMAL)) * 0.30, 0.22, 0.98);
 EMISSION = base_tint.rgb * glow * 1.5;
 SPECULAR = mix(0.32, 0.55, surface_metal);
 float height = weave * fabric * 0.0006 + scratches * surface_metal * 0.0003;
 vec3 dx = dFdx(VERTEX);
 vec3 dy = dFdy(VERTEX);
 vec3 tangent = cross(dy, NORMAL);
 vec3 bitangent = cross(NORMAL, dx);
 float determinant = dot(dx, tangent);
 vec3 gradient = sign(determinant) * (dFdx(height) * tangent + dFdy(height) * bitangent);
 NORMAL = normalize(abs(determinant) * NORMAL - gradient);
}
