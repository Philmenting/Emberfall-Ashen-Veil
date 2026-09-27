shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
uniform vec4 tint : source_color=vec4(0.07,0.055,0.04,0.6);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float noise=hash(floor(UV*37.0));
 float edge=1.0-smoothstep(0.35,1.0,length(p)+noise*0.18);
 ALBEDO=tint.rgb;
 ALPHA=edge*tint.a;
}
