shader_type spatial;
render_mode diffuse_burley;
uniform vec4 stone_tint : source_color = vec4(0.37,0.39,0.4,1.0);
uniform float roughness = 0.84;
uniform sampler2D stone_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_roughness : filter_linear_mipmap, repeat_enable;
varying vec3 world_pos;
varying vec3 world_normal;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
 vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
 // World projection joins the carved props and differently sized masonry;
 // photographs retain their scale rather than stretching over each object.
 vec3 weights=pow(abs(normalize(world_normal)),vec3(6.0));
 weights/=max(dot(weights,vec3(1.0)),0.001);
 vec3 p=world_pos*0.42;
 vec3 stone=texture(stone_color,p.zy).rgb*weights.x+
   texture(stone_color,p.xz).rgb*weights.y+texture(stone_color,p.xy).rgb*weights.z;
 float broad=noise(world_pos*0.55);
 ALBEDO=stone*stone_tint.rgb*2.8*(0.92+broad*0.16);
 float relief=texture(stone_roughness,p.xz).r;
 ROUGHNESS=clamp(roughness*0.65+relief*0.35,0.4,1.0);
 // Horizontal flagstones use the GL normal map in world space. Curved
 // architectural carving retains its authored normals and silhouettes.
 vec3 bump=texture(stone_normal,p.xz).xyz*2.0-1.0;
 vec3 detailed=normalize(world_normal+vec3(bump.x,0.0,bump.y)*0.32*weights.y);
 NORMAL=normalize((VIEW_MATRIX*vec4(detailed,0.0)).xyz);
 SPECULAR=0.24;
}
