shader_type spatial;
render_mode diffuse_burley;
uniform vec4 stone_tint : source_color = vec4(0.37,0.39,0.4,1.0);
uniform float roughness = 0.84;
varying vec3 world_pos;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
 vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float broad=noise(world_pos*0.55);
 float grain=noise(world_pos*14.0)*0.20+noise(world_pos*47.0)*0.07;
 float veins=smoothstep(0.49,0.515,abs(noise(world_pos*3.1)-0.5)*2.0);
 vec3 base=stone_tint.rgb*(0.64+broad*0.62+grain);
 base=mix(base,vec3(0.075,0.084,0.073),smoothstep(0.65,0.88,broad)*0.7);
 ALBEDO=base*(1.0-veins*0.15);
 float pits=hash(floor(world_pos*36.0));
 NORMAL_MAP=normalize(vec3((pits-0.5)*0.24,(grain-0.13)*0.6,1.0))*0.5+0.5;
 ROUGHNESS=clamp(roughness+(broad-0.5)*0.2,0.25,1.0);
 SPECULAR=0.24;
}
