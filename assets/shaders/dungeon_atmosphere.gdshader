shader_type canvas_item;
render_mode unshaded;
void fragment() {
 vec2 p=UV*2.0-1.0;
 float vignette=smoothstep(0.45,1.35,length(p*vec2(0.75,1.0)));
 COLOR=vec4(0.012,0.016,0.025,vignette*0.64);
}
