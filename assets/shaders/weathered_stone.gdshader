shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D stone_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_roughness : filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(0.48,0.50,0.51,1.0);
uniform vec4 mineral_tint : source_color = vec4(0.16,0.20,0.18,1.0);
uniform float roughness = 0.84;
uniform float weathering = 0.12;
uniform float relief = 0.32;
varying vec3 world_pos;
varying vec3 world_normal;
vec3 stone_bump(vec2 uv) {
    // Imported normal maps use two-channel RGTC / EAC compression. Rebuild Z
    // from RG; sampling a missing blue channel would turn lit stone inside out.
    vec2 xy=texture(stone_normal,uv).rg*2.0-1.0;
    return vec3(xy,sqrt(max(0.0,1.0-dot(xy,xy))));
}
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
    // Chipped masonry has authored faces. Project from each face's dominant
    // world axis rather than sampling/blending three full material stacks.
    vec3 axis=abs(world_normal);
    int projection=axis.x>axis.y && axis.x>axis.z ? 0 : (axis.y>axis.z ? 1 : 2);
    vec3 p=world_pos*0.72;
    vec2 uv=projection==0 ? p.zy : (projection==1 ? p.xz : p.xy);
    vec3 stone=texture(stone_color,uv).rgb;
    float pores=texture(stone_roughness,uv).r;
    float damp=weathering*smoothstep(0.42,0.84,pores);
    ALBEDO=mix(mix(vec3(0.32),stone,0.62)*stone_tint.rgb*1.65,mineral_tint.rgb,damp*0.32);
    // Aging belongs to the assembled elevation: broad runoff crosses joints,
    // while the lowest courses collect damp mineral and soot deposits.
    float runoff=texture(stone_roughness,world_pos.xz*0.18+world_pos.yy*vec2(0.011,0.023)).r;
    float broad=texture(stone_roughness,world_pos.xz*0.075).r;
    float footing=(1.0-smoothstep(0.12,2.5,world_pos.y))*mix(0.38,0.78,broad);
    float stain=smoothstep(0.46,0.82,runoff)*(0.16+weathering*0.40);
    ALBEDO=mix(ALBEDO,mineral_tint.rgb*0.32,clamp(footing+stain,0.0,0.78));
    // Joined architectural stone carries relative linear edge/recess tints.
    // Untinted existing meshes supply white, preserving their material.
    ALBEDO*=COLOR.rgb;
    ROUGHNESS=clamp(roughness+(pores-0.5)*0.22-damp*0.28,0.34,0.97);
    SPECULAR=0.38;
    if(relief>0.01){
        vec3 bump=stone_bump(uv);
        vec3 detail=projection==0 ? vec3(bump.z*sign(world_normal.x),bump.y,bump.x)
            : (projection==1 ? vec3(bump.x,bump.z*sign(world_normal.y),bump.y)
            : vec3(bump.x,bump.y,bump.z*sign(world_normal.z)));
        NORMAL=normalize(mat3(VIEW_MATRIX)*normalize(mix(world_normal,detail,relief)));
    }
}
