shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_back;
// A second pass of the hero's real mesh, skin and held prop. It reveals only
// fragments hidden by foreground geometry; it never removes a hostile pixel.
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform float hero_front_depth = 0.0;
uniform float depth_margin = 0.018;
uniform vec4 silhouette_color : source_color = vec4(0.70, 0.63, 0.45, 1.0);

void fragment() {
    float depth = textureLod(scene_depth, SCREEN_UV, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
    vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
    vec4 position = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    float foreground_depth = -position.z / position.w;
    float body_depth = -VERTEX.z;
    // The conservative nearest bound includes the actual held weapon. Depth
    // at or behind that bound can belong to Nyra herself: do not show a rear
    // arm, back face or garment through her own opaque front surface.
    if (foreground_depth >= hero_front_depth - depth_margin ||
            foreground_depth + depth_margin >= body_depth) {
        discard;
    }
    float edge = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.0);
    ALBEDO = silhouette_color.rgb * (0.58 + edge * 0.28);
    // Only this narrow visibility accent blends over a blocker. The outline
    // carries the shape; its low interior fill preserves the guardian finish.
    // Actual body, clothing and weapon PBR materials remain fully opaque.
    ALPHA = 0.10 + edge * 0.56;
}
