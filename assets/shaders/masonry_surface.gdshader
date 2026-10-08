shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Each mesh family supplies one material stack. The artist-authored UVs are
// measured in local metres, with a tangent basis exported alongside them.
uniform sampler2D masonry_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D masonry_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D masonry_roughness : filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(.87,.86,.83,1.0);
uniform vec2 meters_per_repeat = vec2(2.8,1.4);
uniform float pigment_saturation : hint_range(0.0,1.0) = .35;
uniform float dampness : hint_range(0.0,1.0) = .32;
uniform float roughness_bias : hint_range(-.5,.5) = .08;
uniform float relief : hint_range(0.0,1.0) = .80;
varying float world_height;

void vertex() {
    // Regional bays stretch in X/Z. Compensate in the vertex stage so the
    // same block remains the same physical size across differently sized bays.
    vec2 surface_scale = vec2(
        length(mat3(MODEL_MATRIX)*TANGENT),
        length(mat3(MODEL_MATRIX)*BINORMAL));
    UV *= surface_scale/max(meters_per_repeat,vec2(.01));
    world_height = (MODEL_MATRIX*vec4(VERTEX,1.0)).y;
}

void fragment() {
    vec3 pigment = texture(masonry_color,UV).rgb;
    float value = dot(pigment,vec3(.2126,.7152,.0722));
    pigment = mix(vec3(value),pigment,pigment_saturation);
    float foot = 1.0-smoothstep(.05,2.8,world_height);
    ALBEDO = pigment*stone_tint.rgb*COLOR.rgb*(1.0-dampness*foot);
    ROUGHNESS = clamp(texture(masonry_roughness,UV).r*.90+roughness_bias,.48,.96);
    SPECULAR = .28;
    if(relief>.01) {
        // Godot may import normal maps with only RG. Reconstruct Z explicitly.
        vec2 xy = texture(masonry_normal,UV).rg*2.0-1.0;
        vec3 normal = vec3(xy,sqrt(max(0.0,1.0-dot(xy,xy))));
        NORMAL_MAP = normal*.5+.5;
        NORMAL_MAP_DEPTH = relief;
    }
}
