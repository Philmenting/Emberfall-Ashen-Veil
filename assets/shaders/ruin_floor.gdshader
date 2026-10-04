shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D flagstones : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mineral : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D micro_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 floor_tint : source_color = vec4(0.70,0.72,0.72,1.0);
uniform float dampness = 0.0;
uniform float ash = 0.0;
uniform float relief = 0.18;
uniform vec2 room_centers[6];
varying vec3 world_pos;
vec2 mirror_uv(vec2 p) { return abs(fract(p * 0.5) * 2.0 - 1.0); }
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
    // One continuous architectural floor, at metre scale. Mirrored sampling
    // joins the original diffuse tile without claiming it is a seamless scan.
    vec2 p = world_pos.xz;
    vec3 slab = texture(flagstones, mirror_uv(p * 0.185)).rgb;
    float broad = texture(mineral, p * 0.035 + vec2(0.21,0.61)).r;
    float soil = smoothstep(0.045,0.19,broad);
    float value = dot(slab,vec3(0.299,0.587,0.114));
    float seam = 1.0 - smoothstep(0.12,0.27,value);
    vec3 base = mix(vec3(value),slab,0.55) * floor_tint.rgb * 0.66;
    base = mix(base, base * vec3(0.48,0.47,0.44),soil * 0.62);
    base = mix(base, vec3(0.13,0.15,0.14)*floor_tint.rgb,ash*soil*0.32);
    float distance_to_hall = 1000.0;
    for (int i=0; i<6; i++) distance_to_hall=min(distance_to_hall,length((p-room_centers[i])*vec2(1.0,0.85)));
    // Quiet earth-dark perimeter wear separates occupied halls from the
    // unmaintained floor beyond. The floor remains continuous geometry.
    float perimeter = smoothstep(5.5,13.0,distance_to_hall);
    ALBEDO = base * (1.0 - dampness * soil * 0.16) * (1.0-perimeter*0.82);
    ROUGHNESS = clamp(0.87 - dampness * soil * 0.38 + seam * 0.09,0.44,0.97);
    SPECULAR = 0.30;
    vec2 micro = texture(micro_normal,p*0.8).rg*2.0-1.0;
    vec3 n=normalize(vec3(micro.x*relief,1.0,micro.y*relief));
    NORMAL=normalize(mat3(VIEW_MATRIX)*n);
}
