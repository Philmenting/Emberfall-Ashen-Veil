shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
uniform vec4 tint : source_color = vec4(0.07, 0.055, 0.04, 0.6);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p);
 vec2 f = fract(p);
 f = f * f * (3.0 - 2.0 * f);
 return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float grain = noise(UV * 9.0);
 float edge = 1.0 - smoothstep(0.12, 1.0, length(p) + grain * 0.16);
 ALBEDO = tint.rgb;
 ALPHA = edge * edge * tint.a;
}
