shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D mineral : source_color, filter_linear_mipmap, repeat_enable;
uniform float motion = 1.0;
varying vec3 world_pos;
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    VERTEX.y+=sin(world_pos.x*2.1+world_pos.z*1.6+TIME*motion*.54)*.007;
}
void fragment() {
    vec2 p=world_pos.xz;
    float t=TIME*motion;
    float a=sin(p.x*2.5+p.y*.73+t*.54);
    float b=sin(p.y*3.4-p.x*.66-t*.36);
    float silt=texture(mineral,p*.29).r;
    vec3 n=normalize(vec3(a*.046,1.0,b*.035));
    NORMAL=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
    ALBEDO=mix(vec3(.022,.046,.049),vec3(.039,.071,.068),silt*.45);
    ROUGHNESS=.20+silt*.08;
    METALLIC=.08;
    SPECULAR=.76;
}
