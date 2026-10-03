shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Opaque, lit surfaces. UV channels carry authored material properties, never
// screen-facing coordinates. Vertex alpha encodes the garment category.
uniform bool equipment_enabled=false;
uniform float weapon_rank=0.0;
uniform float helm_rank=0.0;
uniform float chest_rank=0.0;
uniform float gloves_rank=0.0;
uniform float boots_rank=0.0;
uniform float accent_rank=0.0;
uniform vec4 weapon_tint:source_color=vec4(0.6,0.5,0.3,1.0);
uniform vec4 helm_tint:source_color=vec4(0.6,0.5,0.3,1.0);
uniform vec4 chest_tint:source_color=vec4(0.6,0.5,0.3,1.0);
uniform vec4 gloves_tint:source_color=vec4(0.6,0.5,0.3,1.0);
uniform vec4 boots_tint:source_color=vec4(0.6,0.5,0.3,1.0);
uniform vec4 accent_tint:source_color=vec4(0.6,0.5,0.3,1.0);
uniform float hit_flash=0.0;
uniform float action_intensity=1.0;
uniform float boss_phase=0.0;
uniform bool boss_surface=false;
uniform float readability=1.0;
uniform float silhouette_focus=0.0;
uniform vec4 focus_tint:source_color=vec4(0.7,0.6,0.4,1.0);
varying vec3 object_position;
void vertex(){ object_position=VERTEX; }
void fragment(){
    float category=round(COLOR.a*8.0);
    float rank=0.0;
    vec3 accent=weapon_tint.rgb;
    if(UV.x<0.5){rank=weapon_rank;accent=weapon_tint.rgb;}
    else if(UV.x<1.5){rank=helm_rank;accent=helm_tint.rgb;}
    else if(UV.x<2.5){rank=chest_rank;accent=chest_tint.rgb;}
    else if(UV.x<3.5){rank=gloves_rank;accent=gloves_tint.rgb;}
    else if(UV.x<4.5){rank=boots_rank;accent=boots_tint.rgb;}
    else {rank=accent_rank;accent=accent_tint.rgb;}
    vec3 color=COLOR.rgb;
    float wear=0.96+0.04*sin(object_position.y*37.0+sin(object_position.x*29.0)*1.8+object_position.z*17.0);
    color*=wear;
    if(equipment_enabled && UV.x>=0.0 && category<0.5 && rank>0.0)
        color=mix(color,accent*0.70,0.08+rank*0.045);
    ALBEDO=mix(color,vec3(0.8,0.72,0.61),hit_flash*0.22)*readability;
    ROUGHNESS=clamp(UV.y,0.38,0.98);
    METALLIC=UV2.x;
    SPECULAR=category==3.0 ? 0.25 : 0.48;
    float edge=pow(1.0-max(dot(NORMAL,VIEW),0.0),3.0);
    EMISSION=color*UV2.y*(0.65+boss_phase*0.25)
        +focus_tint.rgb*edge*silhouette_focus*0.055
        +color*hit_flash*0.20;
}
