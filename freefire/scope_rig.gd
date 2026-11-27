extends Node3D
# Pritsel (optika) 3D modeli. level: 1 = 1x (qizil nuqta), 2 = 2x, 3 = 4x, 4 = 8x
# Qurolning ustiga o'rnatiladi: o'q = -Z (old), +Z = otuvchi tomon, +Y = tepa.
# Linza (orqa tomonda) 2x/4x/8x da haqiqiy yaqinlashtirilgan tasvirni (PIP) ko'rsatadi.

const MULT := [1.0, 1.0, 2.0, 4.0, 8.0]
const LENS_R := [0.0, 0.015, 0.019, 0.024, 0.026]
const RELIEF := [0.0, 0.17, 0.085, 0.075, 0.07]
const LAYER := 524288

const SHADER_SRC := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform sampler2D tex : source_color, filter_linear;
uniform float mode = 0.0;
uniform vec4 tint : source_color = vec4(0.55, 0.75, 1.0, 1.0);

float lnx(float d, float w) {
	return 1.0 - smoothstep(w, w + 0.006, abs(d));
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	if (mode < 0.5) {
		float dotv = 1.0 - smoothstep(0.07, 0.11, r);
		float ring = 1.0 - smoothstep(0.0, 0.04, abs(r - 0.55));
		float m = max(dotv, ring * 0.9);
		ALBEDO = mix(tint.rgb, vec3(1.0, 0.08, 0.04), clamp(m * 1.3, 0.0, 1.0));
		ALPHA = clamp(0.08 + m, 0.0, 1.0);
	} else if (mode < 1.5) {
		vec3 c = texture(tex, UV).rgb;
		c *= mix(0.2, 1.0, smoothstep(1.0, 0.8, r));
		float ch = lnx(p.y, 0.008) * (1.0 - step(0.42, abs(p.x)));
		float cv = lnx(p.x, 0.008) * (1.0 - step(0.42, abs(p.y)));
		float th = lnx(p.y, 0.03) * step(0.42, abs(p.x));
		float tv = lnx(p.x, 0.03) * step(0.42, abs(p.y));
		float dots = 0.0;
		for (int i = 1; i <= 4; i++) {
			float o = float(i) * 0.1;
			dots += 1.0 - smoothstep(0.018, 0.03, length(p - vec2(o, 0.0)));
			dots += 1.0 - smoothstep(0.018, 0.03, length(p + vec2(o, 0.0)));
			dots += 1.0 - smoothstep(0.018, 0.03, length(p - vec2(0.0, o)));
			dots += 1.0 - smoothstep(0.018, 0.03, length(p + vec2(0.0, o)));
		}
		float ret = clamp(max(max(ch, cv), max(max(th, tv), dots)), 0.0, 1.0);
		float cd = 1.0 - smoothstep(0.02, 0.035, r);
		c = mix(c, vec3(0.02), ret * 0.9);
		c = mix(c, vec3(1.0, 0.1, 0.05), cd);
		ALBEDO = c;
		ALPHA = 1.0;
	} else {
		ALBEDO = vec3(0.05, 0.09, 0.14) * (0.4 + 0.6 * (1.0 - r));
		ALPHA = 0.92;
	}
}
"""

static var _shader: Shader = null

var level := 0
var lens_node: Node3D = null
var lens_mat: ShaderMaterial = null


static func _get_shader() -> Shader:
	if _shader == null:
		var sh := Shader.new()
		sh.code = SHADER_SRC
		_shader = sh
	return _shader


func lens_r() -> float:
	return float(LENS_R[clampi(level, 0, 4)])


func mult() -> float:
	return float(MULT[clampi(level, 0, 4)])


func relief() -> float:
	return float(RELIEF[clampi(level, 0, 4)])


func lens_global_pos() -> Vector3:
	if lens_node != null:
		return lens_node.global_position
	return global_position


func set_pip(tex: Texture2D) -> void:
	if lens_mat == null or level < 2:
		return
	lens_mat.set_shader_parameter("tex", tex)
	lens_mat.set_shader_parameter("mode", 1.0)


func set_idle() -> void:
	if lens_mat == null:
		return
	lens_mat.set_shader_parameter("mode", 0.0 if level == 1 else 2.0)


func _mat(col: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	return m


func _place(mi: MeshInstance3D, mat: Material, pos: Vector3) -> void:
	mi.material_override = mat
	mi.position = pos
	mi.layers = LAYER
	add_child(mi)


func _add_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	_place(mi, mat, pos)


func _add_zcyl(r_front: float, r_rear: float, length: float, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_rear
	cm.bottom_radius = r_front
	cm.height = length
	cm.radial_segments = 24
	cm.rings = 1
	mi.mesh = cm
	mi.rotation.x = PI * 0.5
	_place(mi, mat, pos)


func _add_vcyl(r: float, h: float, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 16
	cm.rings = 1
	mi.mesh = cm
	_place(mi, mat, pos)


func _add_xcyl(r: float, length: float, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = length
	cm.radial_segments = 16
	cm.rings = 1
	mi.mesh = cm
	mi.rotation.z = PI * 0.5
	_place(mi, mat, pos)


func _add_lens(pos: Vector3, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(radius * 2.0, radius * 2.0)
	mi.mesh = qm
	lens_mat = ShaderMaterial.new()
	lens_mat.shader = _get_shader()
	lens_mat.set_shader_parameter("mode", 0.0 if level == 1 else 2.0)
	mi.material_override = lens_mat
	mi.position = pos
	mi.layers = LAYER
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	lens_node = mi


func _build_tube(tube_len: float, r: float, r_obj: float, r_eye: float, obj_len: float, big: bool, turrets: bool) -> void:
	var dark := _mat(Color(0.06, 0.06, 0.07), 0.7, 0.4)
	var accent := _mat(Color(0.15, 0.15, 0.17), 0.8, 0.35)
	var glass := _mat(Color(0.08, 0.16, 0.26), 0.2, 0.05)
	glass.emission_enabled = true
	glass.emission = Color(0.05, 0.1, 0.2)
	var ty := 0.012 + r + 0.001
	var eye_len := 0.028
	_add_box(Vector3(0.04, 0.012, tube_len * 0.85), Vector3(0, 0.006, 0), accent)
	_add_zcyl(r, r, tube_len, Vector3(0, ty, 0), dark)
	var zf := -(tube_len * 0.5 + obj_len * 0.5)
	_add_zcyl(r_obj, r, obj_len, Vector3(0, ty, zf), dark)
	var ze := tube_len * 0.5 + eye_len * 0.5
	_add_zcyl(r, r_eye, eye_len, Vector3(0, ty, ze), dark)
	var z_front := -(tube_len * 0.5 + obj_len)
	if big:
		_add_zcyl(r_obj + 0.002, r_obj + 0.002, 0.03, Vector3(0, ty, z_front - 0.015), dark)
		z_front -= 0.03
	_add_zcyl(r_obj - 0.003, r_obj - 0.003, 0.002, Vector3(0, ty, z_front - 0.001), glass)
	for zz in [-tube_len * 0.3, tube_len * 0.3]:
		_add_zcyl(r + 0.004, r + 0.004, 0.012, Vector3(0, ty, zz), accent)
	if turrets:
		_add_vcyl(0.008, 0.018, Vector3(0, ty + r + 0.007, 0), accent)
		_add_xcyl(0.008, 0.018, Vector3(r + 0.007, ty, 0), accent)
		if big:
			_add_xcyl(0.011, 0.016, Vector3(-(r + 0.008), ty, -tube_len * 0.3), accent)
	_add_lens(Vector3(0, ty, tube_len * 0.5 + eye_len + 0.001), float(LENS_R[level]))


func build(lvl: int) -> void:
	level = clampi(lvl, 1, 4)
	match level:
		1:
			_build_tube(0.07, 0.017, 0.019, 0.019, 0.012, false, false)
		2:
			_build_tube(0.10, 0.020, 0.026, 0.024, 0.045, false, false)
		3:
			_build_tube(0.18, 0.023, 0.034, 0.030, 0.050, false, true)
		_:
			_build_tube(0.26, 0.025, 0.040, 0.032, 0.070, true, true)
