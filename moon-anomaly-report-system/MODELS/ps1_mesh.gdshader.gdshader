shader_type spatial;

uniform sampler2D texture_albedo : source_color, hint_default_white;
uniform float snap_resolution : hint_range(16.0, 256.0) = 64.0;
uniform bool affine_warp = true;

varying vec3 affine_uv;

void vertex() {
    vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    
    // Vertex snapping
    clip_pos.xy = floor(clip_pos.xy / clip_pos.w * snap_resolution + 0.5)
                  / snap_resolution * clip_pos.w;
    
    POSITION = clip_pos;
    
    // Pass UVs for affine warping
    affine_uv = vec3(UV * clip_pos.w, clip_pos.w);
}

void fragment() {
    vec2 uv = affine_warp ? (affine_uv.xy / affine_uv.z) : UV;
    ALBEDO = texture(texture_albedo, uv).rgb;
}