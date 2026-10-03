shader_type spatial;
render_mode unshaded,cull_disabled,blend_add,depth_draw_never;
uniform float motion=1.0;
varying vec2 gate_uv;
void vertex(){ gate_uv=UV; }
void fragment(){
    vec2 p=gate_uv*2.0-1.0;
    float radius=length(p*vec2(1.0,0.78));
    float angle=atan(p.y,p.x);
    float curl=sin(angle*5.0-radius*18.0+TIME*motion*0.7);
    float edge=smoothstep(1.0,0.80,radius)*smoothstep(0.42,0.78,radius);
    float veil=(1.0-smoothstep(0.0,0.9,radius))*0.10;
    vec3 ink=mix(vec3(0.12,0.28,0.29),vec3(0.48,0.73,0.67),curl*0.5+0.5);
    ALBEDO=ink;
    ALPHA=edge*(0.14+0.12*curl)+veil;
}
