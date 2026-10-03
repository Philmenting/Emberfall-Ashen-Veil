shader_type spatial;
render_mode diffuse_burley, blend_mix, depth_prepass_alpha;
uniform sampler2D stone_color : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(0.83,0.74,0.59,1.0);
uniform vec2 court_center=vec2(0.0);
varying vec3 world_pos;
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}
void fragment() {
    ALBEDO = mix(vec3(0.24),texture(stone_color,world_pos.xz*0.62).rgb,0.50)*stone_tint.rgb*1.20;
    ROUGHNESS = 0.94;
    SPECULAR = 0.12;
    // Keep the near court solid; distant masonry dissolves into the region art.
    float chamber_distance = length(world_pos.xz - court_center);
    ALPHA = 1.0-smoothstep(23.0,48.0,chamber_distance);
}
