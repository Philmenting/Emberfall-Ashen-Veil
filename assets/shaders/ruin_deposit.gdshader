shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform sampler2D mineral : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 deposit_color : source_color = vec4(0.11,0.10,0.08,0.65);
varying vec3 world_pos;
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 edge=abs(UV*2.0-1.0);
    float shape=1.0-smoothstep(0.30,1.0,max(edge.x,edge.y));
    float grain=texture(mineral,world_pos.xz*0.65).r;
    ALBEDO=deposit_color.rgb;
    ROUGHNESS=0.96;
    ALPHA=shape*(0.35+grain*0.65)*deposit_color.a;
}
