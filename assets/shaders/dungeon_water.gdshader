shader_type spatial;
render_mode cull_disabled, blend_mix, depth_prepass_alpha;
uniform vec4 water_color : source_color = vec4(0.045,0.22,0.23,1.0);
uniform vec4 crest_color : source_color = vec4(0.12,0.4,0.38,1.0);
uniform float lava = 0.0;
uniform float motion = 1.0;
varying vec3 world_pos;
float hash2(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash2(i),hash2(i+vec2(1,0)),f.x),mix(hash2(i+vec2(0,1)),hash2(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_pos.xz;
 float clock=TIME*motion;
 if(lava>0.5) {
  p+=vec2(sin(p.y*0.15+clock*0.03),cos(p.x*0.18-clock*0.02))*0.8;
  float flow=noise2(p*1.10)*0.50+noise2(p*2.47)*0.34+noise2(p*5.6)*0.16;
  float vein=1.0-smoothstep(0.01,0.073,abs(flow-0.49));
  float heat=0.7+0.3*sin(p.x*0.4+p.y*0.6+clock*0.2);
  ALBEDO=mix(vec3(0.045,0.026,0.022),water_color.rgb,vein);
  EMISSION=crest_color.rgb*vein*heat*0.42;
  ROUGHNESS=0.92;
 } else {
  float ripple=sin(p.x*1.8+p.y*0.35+noise2(p*0.5)*3.0+clock*0.5);
  float cross_wave=sin(p.y*2.3-p.x*0.28-clock*0.38);
  float glint=pow(max(0.0,ripple*0.7+cross_wave*0.3),10.0)*0.12;
  ALBEDO=mix(water_color.rgb,crest_color.rgb,noise2(p*0.3)*0.16+glint);
  // NORMAL is in view space. A world-up wave keeps reflections attached
  // to the water as the camera moves, rather than tilting toward the lens.
  vec3 wave_normal=normalize(vec3(ripple*0.07,1.0,cross_wave*0.055));
  NORMAL=normalize((VIEW_MATRIX*vec4(wave_normal,0.0)).xyz);
  ROUGHNESS=0.26+noise2(p*0.4)*0.08;
  METALLIC=0.16;
 }
 // Far and side shores meet the matte through haze, without a hard rectangle.
 vec2 edge=min(UV,vec2(1.0)-UV);
 ALPHA=smoothstep(0.0,0.17,edge.x)*smoothstep(0.0,0.18,edge.y);
}
