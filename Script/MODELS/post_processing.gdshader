shader_type spatial;
render_mode unshaded, fog_disabled;

global uniform vec2 resolution;
global uniform float color_depth;

uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;


void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = floor(SCREEN_UV * resolution) / resolution;
	vec3 color = texture(screen_texture, uv).rgb;
	vec3 quantized_color =  round(color * color_depth) / color_depth;
	ALBEDO = quantized_color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
