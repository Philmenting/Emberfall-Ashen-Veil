shader_type spatial;
render_mode diffuse_burley;
uniform vec4 tint : source_color = vec4(0.3,0.3,0.3,1.0);
uniform float metal = 0.0;
uniform float cloth = 0.0;
uniform bool vertex_materials=false;
varying vec3 local_pos;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
void vertex(){ local_pos=VERTEX; }
void fragment(){
 vec4 base_tint=vertex_materials ? COLOR : tint;
 float surface_metal=vertex_materials ? UV2.x : metal;
 float surface_cloth=vertex_materials ? (1.0-UV2.x) : cloth;
 float grain=hash(floor(local_pos*180.0));
 float weave=sin(UV.x*330.0)*sin(UV.y*260.0)*0.045*surface_cloth;
 float worn=pow(abs(sin(local_pos.y*81.0+local_pos.x*9.0)),30.0)*0.10*surface_metal;
 ALBEDO=base_tint.rgb*(0.84+grain*0.20+weave+worn);
 METALLIC=surface_metal;
 ROUGHNESS=mix(0.91,0.38,surface_metal)+grain*0.12;
 EMISSION=vertex_materials ? base_tint.rgb*UV2.y*1.3 : vec3(0.0);
 SPECULAR=mix(0.25,0.6,surface_metal);
}
