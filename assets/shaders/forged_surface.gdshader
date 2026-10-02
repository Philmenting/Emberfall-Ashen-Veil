shader_type spatial;
render_mode diffuse_burley;
uniform vec4 tint : source_color = vec4(0.3,0.3,0.3,1.0);
uniform float metal = 0.0;
uniform float cloth = 0.0;
uniform bool vertex_materials=false;
uniform sampler2D aged_metal : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D metal_roughness : filter_linear_mipmap, repeat_enable;
varying vec3 local_pos;
varying vec3 surface_axis;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
void vertex(){ local_pos=VERTEX; surface_axis=abs(NORMAL); }
void fragment(){
 vec4 base_tint=vertex_materials ? COLOR : tint;
 float surface_metal=vertex_materials ? UV2.x : metal;
 float surface_cloth=vertex_materials ? (UV.x > 0.5 && UV.x < 1.5 ? 1.0 : 0.0) : cloth;
 float leather=vertex_materials && UV.x > 1.5 && UV.x < 2.5 ? 1.0 : 0.0;
 float skin=vertex_materials && UV.x > 2.5 && UV.x < 3.5 ? 1.0 : 0.0;
 // Fine woven cloth fades with pixel footprint; authored garment folds
 // carry the silhouette. Stable texture mips prevent sparkling metal.
 float frequency=110.0;
 float footprint=max(length(fwidth(local_pos.xy))*frequency,0.001);
 float weave=sin(local_pos.x*frequency)*sin(local_pos.y*frequency)*0.025*surface_cloth*(1.0-smoothstep(0.5,1.5,footprint));
 vec3 patina=vec3(0.6);
 float worn_roughness=0.5;
 if(surface_metal>0.15){
  vec3 w=pow(surface_axis,vec3(4.0)); w/=max(dot(w,vec3(1.0)),0.001);
  vec3 p=local_pos*1.3;
  patina=texture(aged_metal,p.zy).rgb*w.x+texture(aged_metal,p.xz).rgb*w.y+texture(aged_metal,p.xy).rgb*w.z;
  worn_roughness=texture(metal_roughness,p.xy).r;
 }
 ALBEDO=base_tint.rgb*(0.94+weave)*(1.0-surface_metal*0.15)+patina*base_tint.rgb*surface_metal*0.38;
 METALLIC=surface_metal;
 ROUGHNESS=mix(0.90-leather*0.13-skin*0.16,0.51+worn_roughness*0.22,surface_metal);
 EMISSION=vertex_materials ? base_tint.rgb*UV2.y*1.3 : vec3(0.0);
 SPECULAR=mix(0.22+skin*0.10,0.44,surface_metal);
}
