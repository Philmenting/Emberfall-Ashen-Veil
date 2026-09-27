shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 mist_color : source_color=vec4(0.17,0.21,0.24,0.32);
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float cloud=noise(world_pos.xz*0.17+vec2(TIME*0.012,0.0))*0.7+noise(world_pos.xz*0.44-vec2(0.0,TIME*0.019))*0.3;
 ALBEDO=mist_color.rgb;
 ALPHA=smoothstep(0.2,0.85,cloud)*mist_color.a;
}
