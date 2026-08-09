shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 color_ok : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 color_critical : source_color = vec3(1.0, 0.12, 0.08);
uniform float state : hint_range(0.0, 1.0) = 1.0; // 1 = nominal, 0 = critical
uniform float blink_speed : hint_range(0.1, 5.0) = 0.6;
uniform float blink_depth : hint_range(0.0, 1.0) = 0.45;
uniform float emission_strength : hint_range(0.0, 8.0) = 2.0;

void fragment() {
	// MODEL_MATRIX is a per-object constant available directly in fragment()
	// — it isn't interpolated like a varying would be, so every pixel on
	// this light's face reads the exact same seed. Since each light is its
	// own MeshInstance3D node, this origin is already unique per light.
	vec3 origin = MODEL_MATRIX[3].xyz;
	float seed = fract(sin(dot(origin, vec3(12.9898, 78.233, 37.719))) * 43758.5453);

	vec3 base_color = mix(color_critical, color_ok, step(0.5, state));

	float blink = 1.0;
	if (state > 0.5) {
		float t = TIME * blink_speed + seed * 62.831853;
		float pulse = pow(sin(t) * 0.5 + 0.5, 6.0);
		blink = 1.0 - blink_depth * pulse;
	}

	ALBEDO = base_color * blink;
	EMISSION = base_color * emission_strength * blink;
}