shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.02, 0.02, 0.035);
uniform vec3 horizon_color : source_color = vec3(0.05, 0.045, 0.04);
uniform vec3 star_color : source_color = vec3(0.9, 0.9, 0.85);
uniform float star_density : hint_range(0.0, 1.0) = 0.985;
uniform float star_brightness : hint_range(0.0, 5.0) = 1.5;

uniform vec3 earth_direction = vec3(0.3, 0.5, -0.8);
// True angular radius of Earth as seen from the Moon is ~0.95°, which is
// ~0.0166 rad — that's what this value represents (small-angle approx:
// distance between unit direction vectors ≈ angle in radians).
uniform float earth_radius : hint_range(0.0, 0.1) = 0.045;
uniform vec3 earth_color_ocean : source_color = vec3(0.1, 0.25, 0.55);
uniform vec3 earth_color_land : source_color = vec3(0.35, 0.3, 0.15);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 dir = EYEDIR;

	// Airless moon = essentially no atmospheric gradient. Keep the horizon
	// blend subtle — just enough to read as "ground" vs "space."
	float horizon_mix = smoothstep(-0.05, 0.15, dir.y);
	vec3 base = mix(horizon_color, sky_color, horizon_mix);

	// Hash the direction into a fixed grid so stars stay put as the
	// camera rotates instead of swimming.
	vec3 grid = floor(dir * 400.0);
	float n = hash(grid);
	// No atmosphere on the Moon means no scintillation — stars here are
	// steady, hard points of light, never twinkling. (Twinkling on Earth
	// comes entirely from turbulent air bending starlight in flight.)
	float star = step(star_density, n) * star_brightness;

	vec3 color = base + star_color * star;

	// Fixed-position Earth disc. Tidal locking means Earth doesn't rise or
	// set from a fixed point on the near side — it just sits here,
	// essentially motionless for the life of the station.
	vec3 to_earth = normalize(earth_direction);
	float d = distance(dir, to_earth);
	if (d < earth_radius) {
		float shade = smoothstep(earth_radius, earth_radius * 0.3, d);
		float land_mix = hash(floor(dir * 40.0));
		vec3 earth_col = mix(earth_color_ocean, earth_color_land, step(0.6, land_mix));
		color = mix(color, earth_col * shade, 1.0);
	}

	COLOR = color;
}