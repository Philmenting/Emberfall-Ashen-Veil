shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

uniform vec4 magic_color : source_color = vec4(0.47, 0.86, 0.86, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.85;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // The mesh supplies genuine spatial form. Its curved normal defines
    // a soft silhouette and a denser colored center, without white emission.
    float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float density = pow(facing, 0.65);
    float edge = smoothstep(0.0, 0.24, facing);
    ALBEDO = magic_color.rgb * (0.46 + density * 0.42);
    ALPHA = magic_color.a * opacity * fade * edge;
}
