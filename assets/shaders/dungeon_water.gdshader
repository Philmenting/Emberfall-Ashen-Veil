shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 water_color : source_color = vec4(0.045, 0.22, 0.23, 1.0);
uniform vec4 crest_color : source_color = vec4(0.12, 0.4, 0.38, 1.0);
uniform float lava = 0.0;
varying vec3 world_pos;
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
 vec2 i = floor(p);
 vec2 f = fract(p);
 f = f * f * (3.0 - 2.0 * f);
 return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world_pos.xz;
 float height = 0.0;
 if (lava > 0.5) {
  vec2 drift = vec2(TIME * 0.021, -TIME * 0.014);
  vec2 warp = vec2(noise2(p * 0.16 + drift), noise2(p * 0.18 - drift + 7.0));
  vec2 flow_pos = p + (warp - 0.5) * 2.4;
  float crust = noise2(flow_pos * 0.51) * 0.66 + noise2(flow_pos * 1.31) * 0.24 + noise2(flow_pos * 3.1) * 0.10;
  float fissure = 1.0 - smoothstep(0.018, 0.088, abs(crust - 0.50));
  float molten = fissure * fissure;
  float heat = 0.75 + noise2(flow_pos * 0.22 + drift) * 0.25;
  vec3 basalt = vec3(0.014, 0.016, 0.020) * (0.68 + crust * 0.55);
  vec3 hot = mix(crest_color.rgb * 0.8, vec3(1.0, 0.32, 0.055), molten);
  ALBEDO = basalt + water_color.rgb * fissure * 0.06;
  EMISSION = hot * molten * heat * 1.65;
  ROUGHNESS = mix(0.95, 0.65, molten);
  SPECULAR = 0.24;
  height = crust * (1.0 - molten) * 0.09;
 } else {
  vec2 drift = vec2(TIME * 0.018, -TIME * 0.025);
  float swell = noise2(p * 0.62 + drift);
  float ripple = sin(p.x * 2.8 + p.y * 0.75 + swell * 4.0 + TIME * 0.65);
  float cross_ripple = sin(p.y * 3.3 - p.x * 0.48 - TIME * 0.43);
  float foam = pow(max(0.0, ripple * cross_ripple), 9.0) * 0.035;
  ALBEDO = mix(water_color.rgb * 0.72, crest_color.rgb, swell * 0.09 + foam);
  ROUGHNESS = 0.20 + swell * 0.09;
  METALLIC = 0.05;
  SPECULAR = 0.58;
  height = ripple * 0.023 + cross_ripple * 0.012;
 }
 vec3 dx = dFdx(VERTEX);
 vec3 dy = dFdy(VERTEX);
 vec3 tangent = cross(dy, NORMAL);
 vec3 bitangent = cross(NORMAL, dx);
 float determinant = dot(dx, tangent);
 vec3 gradient = sign(determinant) * (dFdx(height) * tangent + dFdy(height) * bitangent);
 NORMAL = normalize(max(abs(determinant), 0.000001) * NORMAL - gradient);
}
