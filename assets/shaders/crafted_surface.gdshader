shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D surfaces : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 cell = vec2(0.0);
uniform vec4 tint : source_color = vec4(0.65,0.60,0.52,1.0);
uniform float metal = 0.0;
uniform float roughness = 0.82;
uniform float scale = 1.4;
varying vec3 local_pos;
varying vec3 local_normal;
vec3 patch(vec2 uv) {
    vec2 repeat_uv=abs(fract(uv*0.5)*2.0-1.0);
    return texture(surfaces,(cell+vec2(0.045)+repeat_uv*0.91)*0.5).rgb;
}
void vertex() { local_pos=VERTEX; local_normal=NORMAL; }
void fragment() {
    vec3 w=pow(abs(local_normal),vec3(4.0));
    w/=max(w.x+w.y+w.z,0.001);
    vec3 p=local_pos*scale;
    vec3 detail=patch(p.zy)*w.x+patch(p.xz)*w.y+patch(p.xy)*w.z;
    float grain=dot(detail,vec3(0.299,0.587,0.114));
    ALBEDO=tint.rgb*(0.30+detail*2.2);
    METALLIC=metal;
    ROUGHNESS=clamp(roughness+(grain-0.22)*0.40,0.40,0.98);
    SPECULAR=0.35;
}
