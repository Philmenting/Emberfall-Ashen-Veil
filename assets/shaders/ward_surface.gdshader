shader_type spatial;
render_mode unshaded,cull_disabled,blend_add,depth_draw_never;
uniform vec4 ward_color:source_color=vec4(0.45,0.76,0.76,1.0);
void fragment(){
    float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.4);
    ALBEDO=ward_color.rgb;
    ALPHA=0.025+rim*0.27;
}
