shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform vec4 flame_color : source_color=vec4(1.0,0.3,0.04,1.0);
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=UV*2.0-1.0;
 p.x+=sin(UV.y*9.0-TIME*7.0)*0.16*UV.y;
 float width=mix(0.07,0.52,UV.y);
 float fire=(1.0-smoothstep(width*0.1,width,abs(p.x)))*smoothstep(0.0,0.18,UV.y)*(1.0-smoothstep(0.72,1.0,UV.y));
 ALBEDO=mix(flame_color.rgb,vec3(1.0,0.87,0.5),fire*fire);
 ALPHA=fire*0.9;
}
