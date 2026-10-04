shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D masonry_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D masonry_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D masonry_roughness : filter_linear_mipmap, repeat_enable;
uniform sampler2D cap_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cap_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D cap_roughness : filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(.87,.86,.83,1.0);
uniform float relief = .80;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
    vec3 base=normalize(world_normal);
    vec3 axis=abs(base);
    bool cap=axis.y>.70;
    // Signed world bases preserve course height across adjacent, stretched bays.
    vec3 tangent=cap ? vec3(1,0,0) : (axis.x>axis.z ? vec3(0,0,-sign(base.x)) : vec3(sign(base.z),0,0));
    vec3 bitangent=cap ? vec3(0,0,-sign(base.y)) : vec3(0,1,0);
    vec2 uv=vec2(dot(world_pos,tangent),dot(world_pos,bitangent))/(cap ? vec2(1.4) : vec2(2.8,1.4));
    vec3 pigment=cap ? texture(cap_color,uv).rgb : texture(masonry_color,uv).rgb;
    float value=dot(pigment,vec3(.2126,.7152,.0722));
    pigment=mix(vec3(value),pigment,.35);
    // Damp darkens actual stone detail instead of replacing it with a flat wash.
    float foot=1.0-smoothstep(.05,2.8,world_pos.y);
    ALBEDO=pigment*stone_tint.rgb*COLOR.rgb*mix(1.0,.68,foot);
    float rough=cap ? texture(cap_roughness,uv).r : texture(masonry_roughness,uv).r;
    ROUGHNESS=clamp(rough*.90+.08,.48,.96);
    SPECULAR=.28;
    if(relief>.01) {
        vec2 xy=(cap ? texture(cap_normal,uv).rg : texture(masonry_normal,uv).rg)*2.0-1.0;
        vec3 bump=vec3(xy,sqrt(max(0.0,1.0-dot(xy,xy))));
        tangent=normalize(tangent-base*dot(tangent,base));
        bitangent=normalize(cross(base,tangent));
        vec3 detail=normalize(tangent*bump.x+bitangent*bump.y+base*bump.z);
        NORMAL=normalize(mat3(VIEW_MATRIX)*normalize(mix(base,detail,cap ? relief*.40 : relief)));
    }
}
