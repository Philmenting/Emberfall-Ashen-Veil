shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D atlas_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 atlas_grid = vec2(3.0, 2.0);
uniform vec2 atlas_origin = vec2(0.0);
uniform float pose_frame = 0.0;
uniform vec4 frame_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool equipment_enabled = false;
uniform float weapon_rank = 0.0;
uniform float helm_rank = 0.0;
uniform float chest_rank = 0.0;
uniform float gloves_rank = 0.0;
uniform float boots_rank = 0.0;
uniform float accent_rank = 0.0;
uniform vec4 weapon_tint : source_color = vec4(0.75, 0.65, 0.46, 1.0);
uniform vec4 helm_tint : source_color = vec4(0.75, 0.65, 0.46, 1.0);
uniform vec4 chest_tint : source_color = vec4(0.75, 0.65, 0.46, 1.0);
uniform vec4 gloves_tint : source_color = vec4(0.75, 0.65, 0.46, 1.0);
uniform vec4 boots_tint : source_color = vec4(0.75, 0.65, 0.46, 1.0);
uniform vec4 accent_tint : source_color = vec4(0.75, 0.65, 0.46, 1.0);
uniform float hit_flash = 0.0;
uniform float action_intensity = 1.0;
uniform float boss_phase = 0.0;
uniform bool boss_surface = false;
uniform float lean = 0.0;
uniform float sprite_opacity = 1.0;
uniform float facing_sign = 1.0;
uniform vec2 sprite_offset = vec2(0.0);
uniform float readability = 1.0;
uniform float silhouette_focus = 0.0;
uniform vec4 focus_tint : source_color = vec4(0.94, 0.86, 0.67, 1.0);
uniform bool layered_parts = false;
uniform bool animated_bow = false;
uniform vec4 bow_string_source = vec4(1297.0,60.0,1283.0,409.0);

varying vec2 cell_uv;
varying vec2 equipment_uv;
varying float string_part;

void vertex() {
    cell_uv = UV;
    equipment_uv = layered_parts ? COLOR.rg : UV;
    string_part = layered_parts ? COLOR.b : 0.0;
    // A vertical cutout stays grounded while its horizontal axis faces the
    // live 3D camera. Simulation yaw never turns the painting into a thin card.
    vec3 forward = normalize(vec3(INV_VIEW_MATRIX[3].x - MODEL_MATRIX[3].x, 0.0, INV_VIEW_MATRIX[3].z - MODEL_MATRIX[3].z));
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 dimensions = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
    mat4 facing = mat4(vec4(right * dimensions.x, 0.0), vec4(0.0, dimensions.y, 0.0, 0.0), vec4(forward * dimensions.z, 0.0), MODEL_MATRIX[3]);
    MODELVIEW_MATRIX = VIEW_MATRIX * facing;
    // A short impact lean is separate from actual authored action poses.
    float x = VERTEX.x;
    VERTEX.x = cos(lean) * x - sin(lean) * VERTEX.y;
    VERTEX.y = sin(lean) * x + cos(lean) * VERTEX.y;
    VERTEX.xy += sprite_offset;
    VERTEX.x *= facing_sign;
}

void fragment() {
    // Each cached mesh follows the authored alpha silhouette. Source regions
    // map the original PNG without cutting weapons at nominal atlas seams.
    vec2 source_uv = frame_region.xy + cell_uv * frame_region.zw;
    vec4 painting = texture(atlas_texture, source_uv);
    if (animated_bow && layered_parts && string_part < 0.5) {
        vec2 pixel = source_uv * vec2(textureSize(atlas_texture, 0));
        vec2 segment = bow_string_source.zw - bow_string_source.xy;
        float progress = dot(pixel - bow_string_source.xy, segment) / dot(segment, segment);
        float distance_to_string = length(pixel - bow_string_source.xy - segment * clamp(progress, 0.0, 1.0));
        if (progress > 0.0 && progress < 1.0 && distance_to_string < 3.4) painting.a = 0.0;
    }
    if (string_part > 0.5) painting = vec4(0.64, 0.52, 0.33, 1.0);
    vec3 color = painting.rgb;
    // An inward, restrained contour separates the heroine/actual target from
    // adjacent paintings. It adds no surface, glow shell or screen-wide pass.
    if (silhouette_focus > 0.01 && string_part < 0.5) {
        vec2 texel = 1.6 / vec2(textureSize(atlas_texture, 0));
        float inside = min(min(texture(atlas_texture, source_uv + vec2(texel.x, 0.0)).a, texture(atlas_texture, source_uv - vec2(texel.x, 0.0)).a), min(texture(atlas_texture, source_uv + vec2(0.0, texel.y)).a, texture(atlas_texture, source_uv - vec2(0.0, texel.y)).a));
        float contour = smoothstep(0.15, 0.65, painting.a - inside);
        color = mix(color, focus_tint.rgb, contour * silhouette_focus * 0.65);
    }
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luminance), color, 0.55 + readability * 0.45) * (0.65 + readability * 0.35);
    float edge = 0.0;
    if (equipment_enabled) {
        vec2 texel = 2.0 / vec2(textureSize(atlas_texture, 0));
        float neighbor = max(max(texture(atlas_texture, source_uv + vec2(texel.x, 0.0)).a, texture(atlas_texture, source_uv - vec2(texel.x, 0.0)).a), max(texture(atlas_texture, source_uv + vec2(0.0, texel.y)).a, texture(atlas_texture, source_uv - vec2(0.0, texel.y)).a));
        edge = clamp(neighbor - painting.a, 0.0, 1.0);
        // Six honest equipment quality accents, confined to their physical UV
        // regions. These communicate grade; they do not claim item-mesh swaps.
        float rank = chest_rank;
        vec3 accent = chest_tint.rgb;
        if (equipment_uv.y < 0.24 && equipment_uv.x > 0.31 && equipment_uv.x < 0.68) { rank = helm_rank; accent = helm_tint.rgb; }
        else if (equipment_uv.y > 0.76) { rank = boots_rank; accent = boots_tint.rgb; }
        else if (equipment_uv.y > 0.40 && equipment_uv.y < 0.68 && (equipment_uv.x < 0.31 || equipment_uv.x > 0.70)) { rank = gloves_rank; accent = gloves_tint.rgb; }
        else if (equipment_uv.x > 0.70 || (equipment_uv.x < 0.31 && equipment_uv.y < 0.40)) { rank = weapon_rank; accent = weapon_tint.rgb; }
        if (distance(equipment_uv, vec2(0.51, 0.40)) < 0.057) { rank = accent_rank; accent = accent_tint.rgb; }
        float bronze = smoothstep(0.08, 0.24, color.r - color.b) * smoothstep(0.16, 0.42, dot(color, vec3(0.299, 0.587, 0.114)));
        // Only weathered bronze highlights receive a small grade tint; skin,
        // white hair, plum cloth and the painted anatomy retain their values.
        if (equipment_uv.y > 0.24 || equipment_uv.y < 0.15) color = mix(color, color * mix(vec3(1.0), accent * 1.35, 0.12), bronze * rank * 0.11);
        color = mix(color, accent, edge * rank * 0.11);
        edge *= min(rank * 0.12, 0.42);
    }
    color = mix(color, vec3(1.0, 0.86, 0.64), hit_flash * 0.36);
    if (boss_surface) {
        float bronze = smoothstep(0.10, 0.28, color.r - color.b);
        color += vec3(0.18, 0.045, 0.008) * bronze * boss_phase * 0.16;
    }
    ALBEDO = color;
    ALPHA = max(painting.a, edge) * sprite_opacity;
    ALPHA_SCISSOR_THRESHOLD = 0.045;
}
