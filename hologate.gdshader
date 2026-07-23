shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec4 tint : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.4;
uniform float fresnel_power : hint_range(0.5, 4.0) = 2.0;

void fragment() {
    float scan = fract(UV.y * 20.0 - TIME * scroll_speed);
    float scanline = smoothstep(0.0, 0.1, scan) * smoothstep(1.0, 0.9, scan);

    vec3 view_dir = normalize(VIEW);
    float fresnel = pow(1.0 - abs(dot(NORMAL, view_dir)), fresnel_power);

    ALBEDO = tint.rgb;
    ALPHA = clamp(fresnel + scanline * 0.3, 0.0, 0.9);
}