shader_type spatial;
render_mode diffuse_burley, blend_mix, depth_prepass_alpha;
uniform sampler2D stone_color : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(0.83,0.74,0.59,1.0);
varying vec3 world_pos;
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}
void fragment() {
    ALBEDO = texture(stone_color,world_pos.xz*0.23).rgb*stone_tint.rgb*0.64;
    ROUGHNESS = 0.94;
    SPECULAR = 0.12;
    // Keep the near court solid; distant masonry dissolves into the region art.
    float camera_distance = length(world_pos.xz - CAMERA_POSITION_WORLD.xz);
    ALPHA = 1.0-smoothstep(16.0,30.0,camera_distance);
}
