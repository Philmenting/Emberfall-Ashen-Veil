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
uniform sampler2D metal_grain:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D metal_roughness:filter_linear_mipmap,repeat_enable;
uniform sampler2D field_surfaces:source_color,filter_linear_mipmap,repeat_disable;
uniform bool portrait_crop=false;
uniform sampler2D face_albedo:source_color,filter_linear_mipmap,repeat_disable;
varying vec3 object_position;
void vertex(){ object_position=CUSTOM0.xyz; }
float face_v(float y) {
    // Authored geometry landmarks after the common adult-proportion export.
    // Image coordinates are measured from the original patch, not guessed.
    float eye_y=1.94306, tip_y=1.90522, base_y=1.89748, mouth_y=1.86738;
    if(y>=eye_y) return mix(444.0/1254.0,0.0,clamp((y-eye_y)/(2.051-eye_y),0.0,1.0));
    if(y>=tip_y) return mix(752.0/1254.0,444.0/1254.0,(y-tip_y)/(eye_y-tip_y));
    if(y>=base_y) return mix(834.0/1254.0,752.0/1254.0,(y-base_y)/(tip_y-base_y));
    if(y>=mouth_y) return mix(1003.0/1254.0,834.0/1254.0,(y-mouth_y)/(base_y-mouth_y));
    return mix(1.0,1003.0/1254.0,clamp((y-1.796)/(mouth_y-1.796),0.0,1.0));
}
void fragment(){
    if(portrait_crop && UV.x>=0.0 && UV.x<0.5) discard;
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
    // Rest-space coordinates keep the finish attached to the animated garment.
    vec2 grain_uv=object_position.xy*1.35+object_position.zy*0.34;
    float grain=dot(texture(metal_grain,grain_uv).rgb,vec3(0.299,0.587,0.114));
    float etched=texture(metal_roughness,grain_uv).r;
    float metal=UV2.x;
    vec2 cell=metal>0.3 ? vec2(1.0,1.0) : (category==2.0 ? vec2(1.0,0.0) : vec2(0.0,1.0));
    vec2 repeat_uv=abs(fract(grain_uv*(metal>0.3 ? 1.1 : 2.0))*2.0-1.0);
    vec3 surface=texture(field_surfaces,(cell+vec2(0.045)+repeat_uv*0.91)*0.5).rgb;
    float wear=dot(surface,vec3(0.299,0.587,0.114));
    color*=mix(0.76+wear*1.5,0.58+wear*1.75,metal);
    // Woven cloth carries a quiet fibre grain. Large bright atlas variation
    // must not turn the animated fold surfaces into pebbled, reflective stone.
    if(category==1.0) color=COLOR.rgb*(0.94+wear*0.20);
    if(category==2.0) color=COLOR.rgb*(0.90+wear*0.28);
    if(category==3.0) color=COLOR.rgb*(0.97+wear*0.07);
    if(category==4.0 || category==5.0) color=COLOR.rgb*(0.95+grain*0.12);
    if(category==6.0 || category==7.0) {
        vec2 face_uv=vec2(0.5+object_position.x/0.1894,face_v(object_position.y));
        vec3 complexion=texture(face_albedo,clamp(face_uv,vec2(0.002),vec2(0.998))).rgb;
        float front=smoothstep(0.045,0.095,-object_position.z);
        float cheek=1.0-smoothstep(0.09,0.113,abs(object_position.x));
        float head=smoothstep(1.782,1.822,object_position.y);
        color=mix(COLOR.rgb,complexion,front*cheek*head);
    }
    if(equipment_enabled && UV.x>=0.0 && category<0.5 && rank>0.0)
        color=mix(color,accent*0.70,0.08+rank*0.045);
    ALBEDO=mix(color,vec3(0.8,0.72,0.61),hit_flash*0.22)*readability;
    ROUGHNESS=clamp(UV.y+(etched-0.5)*metal*0.26+(wear-0.2)*0.18,0.40,0.98);
    if(category==1.0) ROUGHNESS=clamp(0.92+wear*0.04,0.92,0.98);
    METALLIC=metal;
    SPECULAR=(category==3.0 || category>=6.0) ? 0.25 : 0.48;
    if(category==1.0) SPECULAR=0.18;
    float edge=pow(1.0-max(dot(NORMAL,VIEW),0.0),3.0);
    EMISSION=color*UV2.y*(0.65+boss_phase*0.25)
        +focus_tint.rgb*edge*silhouette_focus*0.055
        +color*hit_flash*0.20;
}
