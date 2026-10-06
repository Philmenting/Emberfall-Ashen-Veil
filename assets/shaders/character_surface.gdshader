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
// Only foreground hostile bodies use this stationary screen-door cutaway.
// The world supplies the projected, animated hero skin rather than a marker.
uniform float hero_cutaway=0.0;
uniform vec2 hero_window_center=vec2(0.0);
uniform vec2 hero_window_extent=vec2(1.0);
uniform float hero_view_depth=0.0;
uniform sampler2D metal_grain:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D metal_roughness:filter_linear_mipmap,repeat_enable;
uniform sampler2D field_surfaces:source_color,filter_linear_mipmap,repeat_disable;
uniform bool portrait_crop=false;
uniform sampler2D face_albedo:source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D body_albedo:source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D body_normal:hint_normal,filter_linear_mipmap,repeat_disable;
uniform sampler2D body_orm:filter_linear_mipmap,repeat_disable;
varying vec3 object_position;
varying vec3 authored_uv;
varying vec3 authored_emission;
void vertex(){ object_position=CUSTOM0.xyz; authored_uv=CUSTOM1.xyz; authored_emission=CUSTOM2.xyz; }
vec3 encode_linear_emission(vec3 value) {
    return mix(value*12.92,1.055*pow(max(value,vec3(0.0)),vec3(1.0/2.4))-0.055,step(vec3(0.0031308),value));
}
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
    if(hero_cutaway>0.0 && -VERTEX.z<hero_view_depth) {
        vec2 window=abs((FRAGCOORD.xy-hero_window_center)/max(hero_window_extent,vec2(1.0)));
        float coverage=1.0-smoothstep(0.68,1.08,max(window.x,window.y));
        // An ordered 4x4 pattern has no frame-dependent noise or alpha sort.
        // Depth-tested opaque fragments outside the hero keep their full finish.
        ivec2 cell=ivec2(mod(floor(FRAGCOORD.xy),4.0));
        int bayer[16]=int[16](0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5);
        float threshold=(float(bayer[cell.y*4+cell.x])+0.5)/16.0;
        if(threshold<hero_cutaway*coverage) discard;
    }
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
    float grain=0.5;
    float etched=0.5;
    float wear=0.25;
    float metal=UV2.x;
    bool source_body=authored_uv.z>0.5;
    NORMAL_MAP=vec3(0.5,0.5,1.0);
    if(source_body) {
        // The sewn surface and its bake share the source UVs through skinning.
        // The normal frame is exported with the mesh, not projected in space.
        // Source-guide hair cards share this atlas. Their authored coverage
        // cuts the strand edges; all opaque body texels retain alpha 1.
        vec4 source_albedo=texture(body_albedo,authored_uv.xy);
        if(source_albedo.a<0.35) discard;
        color=source_albedo.rgb;
        vec3 orm=texture(body_orm,authored_uv.xy).rgb;
        metal=orm.b;
        AO=orm.r;
        ROUGHNESS=clamp(orm.g,0.30,0.99);
        NORMAL_MAP=texture(body_normal,authored_uv.xy).rgb;
        NORMAL_MAP_DEPTH=1.0;
    } else {
    // Rest-space coordinates keep the finish attached to the animated garment.
    vec2 grain_uv=object_position.xy*1.35+object_position.zy*0.34;
    grain=dot(texture(metal_grain,grain_uv).rgb,vec3(0.299,0.587,0.114));
    etched=texture(metal_roughness,grain_uv).r;
    vec2 cell=metal>0.3 ? vec2(1.0,1.0) : (category==2.0 ? vec2(1.0,0.0) : vec2(0.0,1.0));
    vec2 repeat_uv=abs(fract(grain_uv*(metal>0.3 ? 1.1 : 2.0))*2.0-1.0);
    vec3 surface=texture(field_surfaces,(cell+vec2(0.045)+repeat_uv*0.91)*0.5).rgb;
    wear=dot(surface,vec3(0.299,0.587,0.114));
    // The GLTF factor -> sRGB material -> linear vertex color chain has been
    // measured. COLOR is already linear albedo, not a color needing another
    // gamma operation or a high-contrast atlas multiplier. Authored broad
    // planes and piece pigments carry the body; material grain stays secondary.
    color*=0.94+clamp(wear,0.0,0.7)*0.14;
    if(metal>0.3) color=COLOR.rgb*(0.96+(grain-0.35)*0.10);
    if(category==1.0) color=COLOR.rgb*(0.975+(wear-0.25)*0.065);
    if(category==2.0) color=COLOR.rgb*(0.97+(wear-0.25)*0.10);
    if(category==3.0) color=COLOR.rgb*(0.97+wear*0.07);
    if(category==4.0) color=COLOR.rgb*(0.95+grain*0.12);
    if(category==5.0) color=COLOR.rgb*(0.985+(grain-0.35)*0.055);
    if(category==6.0 || category==7.0) {
        vec2 face_uv=vec2(0.5+object_position.x/0.1894,face_v(object_position.y));
        vec3 complexion=texture(face_albedo,clamp(face_uv,vec2(0.002),vec2(0.998))).rgb;
        float front=smoothstep(0.045,0.095,-object_position.z);
        float cheek=1.0-smoothstep(0.09,0.113,abs(object_position.x));
        float head=smoothstep(1.782,1.822,object_position.y);
        color=mix(COLOR.rgb,complexion,front*cheek*head);
    }
    ROUGHNESS=clamp(UV.y+(etched-0.5)*metal*0.075,0.37,0.97);
    if(category==1.0) ROUGHNESS=clamp(UV.y+(wear-0.25)*0.025,0.86,0.96);
    if(category==2.0) ROUGHNESS=clamp(UV.y+(wear-0.25)*0.045,0.70,0.87);
    if(category==5.0) ROUGHNESS=clamp(UV.y+(grain-0.35)*0.025,0.78,0.91);
    // The calibrated face's material response is retained independently of
    // the revised equipment finish.
    if(category>=6.0) ROUGHNESS=clamp(UV.y+(wear-0.2)*0.18,0.40,0.98);
    }
    if(equipment_enabled && UV.x>=0.0 && (category<0.5 || (source_body && metal>0.3)) && rank>0.0)
        color=mix(color,accent*0.70,0.08+rank*0.045);
    ALBEDO=mix(color,vec3(0.8,0.72,0.61),hit_flash*0.22)*readability;
    METALLIC=metal;
    SPECULAR=(category==3.0 || category>=6.0) ? 0.25 : 0.48;
    if(category==1.0) SPECULAR=0.22;
    if(category==2.0) SPECULAR=0.32;
    if(category==5.0) SPECULAR=0.29;
    float edge=pow(1.0-max(dot(NORMAL,VIEW),0.0),3.0);
    vec3 material_emission=color*UV2.y*(0.65+boss_phase*0.25);
    if(source_body) {
        material_emission=authored_emission*UV2.y*(1.0+boss_phase*0.25);
        // Compatibility decodes EMISSION after fragment(). Encode the complete
        // linear pigment × intensity once, including dark gem emission.
        if(OUTPUT_IS_SRGB) material_emission=encode_linear_emission(material_emission);
    }
    EMISSION=material_emission
        +focus_tint.rgb*edge*silhouette_focus*0.055
        +color*hit_flash*0.20;
}
