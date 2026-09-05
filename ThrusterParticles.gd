# ThrusterParticles.gd
# Attach to a Node3D positioned at a lantern's orb (the little thruster
# sphere). Builds a GPUParticles3D ember stream + a pulsing glow disc
# entirely in code, so there's nothing to hand-edit in the .tscn.
#
# USAGE
#   1. In floating_lantern_garage.tscn, add a Node3D as a sibling of the
#      lantern's OmniLight3D, positioned at the orb.
#   2. Attach this script to it.
#   3. Done — _ready() does the rest.
#
# Matches project conventions: unshaded StandardMaterial3D, emission_enabled,
# TRANSPARENCY_ALPHA (see interactive_screen.gd / hologate.gdshader).

extends Node3D

@export var ember_color: Color = Color(0.788, 0.541, 0.180, 1.0)  # matches palette #C98A2E
@export var ember_count: int = 8
@export var ember_lifetime: float = 1.3
@export var ember_size: float = 0.035
@export var ember_rise_speed: float = 0.25   # embers drift UP past the lantern
@export var ember_spread: float = 0.06       # sideways drift/jitter

@export var glow_enabled: bool = true
@export var glow_size: float = 0.18
@export var glow_pulse_speed: float = 1.6
@export var glow_min_energy: float = 1.0
@export var glow_max_energy: float = 2.2

var _particles: GPUParticles3D
var _glow_mesh: MeshInstance3D
var _glow_mat: StandardMaterial3D
var _time: float = 0.0

func _ready() -> void:
	_build_embers()
	if glow_enabled:
		_build_glow_disc()

# ── Embers ────────────────────────────────────────────────────────────────

func _build_embers() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = ember_count
	_particles.lifetime = ember_lifetime
	_particles.explosiveness = 0.0
	_particles.randomness = 0.6
	_particles.local_coords = false
	add_child(_particles)

	var quad := QuadMesh.new()
	quad.size = Vector2(ember_size, ember_size)
	_particles.draw_pass_1 = quad

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = ember_color
	mat.emission_enabled = true
	mat.emission = ember_color
	mat.emission_energy_multiplier = 2.0
	quad.material = mat

	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = 0.05
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 25.0
	proc.gravity = Vector3.ZERO
	proc.initial_velocity_min = ember_rise_speed * 0.7
	proc.initial_velocity_max = ember_rise_speed * 1.3
	proc.linear_accel_min = -0.05
	proc.linear_accel_max = 0.05
	proc.scale_min = 0.6
	proc.scale_max = 1.2
	proc.color = ember_color

	# Fade in-then-out over the ember's life via a small alpha ramp.
	var alpha_ramp := Gradient.new()
	alpha_ramp.set_color(0, Color(1, 1, 1, 0))
	alpha_ramp.add_point(0.15, Color(1, 1, 1, 1))
	alpha_ramp.add_point(0.75, Color(1, 1, 1, 1))
	alpha_ramp.set_color(1, Color(1, 1, 1, 0))
	var alpha_tex := GradientTexture1D.new()
	alpha_tex.gradient = alpha_ramp
	proc.alpha_curve = alpha_tex

	proc.turbulence_enabled = true
	proc.turbulence_noise_strength = ember_spread
	proc.turbulence_noise_scale = 2.0
	proc.turbulence_influence_min = 0.3
	proc.turbulence_influence_max = 0.6

	_particles.process_material = proc

# ── Pulsing glow disc ─────────────────────────────────────────────────────

func _build_glow_disc() -> void:
	_glow_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(glow_size, glow_size)
	_glow_mesh.mesh = quad
	# Face down toward the "thrust" direction; billboard also keeps it
	# camera-facing so orientation isn't critical either way.
	add_child(_glow_mesh)

	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_glow_mat.albedo_color = ember_color
	_glow_mat.emission_enabled = true
	_glow_mat.emission = ember_color
	_glow_mat.emission_energy_multiplier = glow_min_energy
	_glow_mesh.set_surface_override_material(0, _glow_mat)

	set_process(true)

func _process(delta: float) -> void:
	if not glow_enabled or _glow_mat == null:
		return
	_time += delta
	var pulse := (sin(_time * glow_pulse_speed) * 0.5) + 0.5
	_glow_mat.emission_energy_multiplier = lerp(glow_min_energy, glow_max_energy, pulse)
