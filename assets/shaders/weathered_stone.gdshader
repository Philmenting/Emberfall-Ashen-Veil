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
    vec3 w=pow(abs(world_normal),vec3(5.0));
    w/=max(w.x+w.y+w.z,0.001);
    vec3 p=world_pos*0.72;
    vec3 stone=texture(stone_color,p.zy).rgb*w.x+texture(stone_color,p.xz).rgb*w.y+texture(stone_color,p.xy).rgb*w.z;
    float pores=texture(stone_roughness,p.zy).r*w.x+texture(stone_roughness,p.xz).r*w.y+texture(stone_roughness,p.xy).r*w.z;
    float damp=weathering*smoothstep(0.42,0.84,pores);
    ALBEDO=mix(mix(vec3(0.32),stone,0.62)*stone_tint.rgb*1.65,mineral_tint.rgb,damp*0.32);
    ROUGHNESS=clamp(roughness+(pores-0.5)*0.22-damp*0.28,0.34,0.97);
    SPECULAR=0.38;
    if(relief>0.01){
        vec3 nx=stone_bump(p.zy);
        vec3 ny=stone_bump(p.xz);
        vec3 nz=stone_bump(p.xy);
        vec3 detail=vec3(nx.z*sign(world_normal.x),nx.y,nx.x)*w.x
            +vec3(ny.x,ny.z*sign(world_normal.y),ny.y)*w.y
            +vec3(nz.x,nz.y,nz.z*sign(world_normal.z))*w.z;
        NORMAL=normalize(mat3(VIEW_MATRIX)*normalize(mix(world_normal,detail,relief)));
    }
}
