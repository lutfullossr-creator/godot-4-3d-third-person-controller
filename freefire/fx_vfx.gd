extends RefCounted
# fx_vfx.gd (3-akkaunt). Core'da yo'q effektlar: qon, qo'nish changi, gilza, o'q chiqargandagi tutun.
# Optimallashtirish: CPUParticles3D (mobil uchun yengil), har tur uchun belgilangan hovuz (yangi obyekt yaratilmaydi),
# kameradan 40 m dan uzoq effekt chizilmaydi. Hook kerak emas: on_hurt, on_fire, update (mavjud).

const MAX := {"blood": 10, "dust": 6, "smoke": 8, "shell": 10}
const FAR := 40.0

var _pool := {}
var _idx := {}
var _consts := {}


func _make(kind: String) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.emitting = false
	e.one_shot = true
	e.explosiveness = 1.0
	e.local_coords = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var col := Color.WHITE
	var mesh: PrimitiveMesh
	match kind:
		"blood":
			var s := SphereMesh.new()
			s.radius = 0.03
			s.height = 0.06
			s.radial_segments = 5
			s.rings = 3
			mesh = s
			col = Color(0.7, 0.03, 0.03, 1.0)
			e.amount = 16
			e.lifetime = 0.55
			e.spread = 75.0
			e.initial_velocity_min = 1.2
			e.initial_velocity_max = 3.2
			e.gravity = Vector3(0.0, -9.0, 0.0)
			e.scale_amount_min = 0.8
			e.scale_amount_max = 1.4
		"dust":
			var s2 := SphereMesh.new()
			s2.radius = 0.12
			s2.height = 0.24
			s2.radial_segments = 6
			s2.rings = 3
			mesh = s2
			col = Color(0.75, 0.70, 0.60, 0.7)
			e.amount = 8
			e.lifetime = 0.6
			e.spread = 85.0
			e.initial_velocity_min = 0.8
			e.initial_velocity_max = 1.8
			e.gravity = Vector3(0.0, -1.0, 0.0)
			e.scale_amount_min = 1.0
			e.scale_amount_max = 2.2
		"smoke":
			var s3 := SphereMesh.new()
			s3.radius = 0.06
			s3.height = 0.12
			s3.radial_segments = 5
			s3.rings = 3
			mesh = s3
			col = Color(0.8, 0.8, 0.8, 0.35)
			e.amount = 3
			e.lifetime = 0.7
			e.spread = 25.0
			e.initial_velocity_min = 0.2
			e.initial_velocity_max = 0.5
			e.gravity = Vector3(0.0, 0.3, 0.0)
			e.scale_amount_min = 1.0
			e.scale_amount_max = 2.0
		_:
			var b := BoxMesh.new()
			b.size = Vector3(0.012, 0.012, 0.04)
			mesh = b
			col = Color(0.9, 0.7, 0.25, 1.0)
			e.amount = 1
			e.lifetime = 0.9
			e.spread = 15.0
			e.initial_velocity_min = 1.6
			e.initial_velocity_max = 2.4
			e.gravity = Vector3(0.0, -9.8, 0.0)
			e.angular_velocity_min = 200.0
			e.angular_velocity_max = 600.0
	mesh.material = mat
	e.mesh = mesh
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 1.0])
	gr.colors = PackedColorArray([col, Color(col.r, col.g, col.b, 0.0)])
	e.color_ramp = gr
	return e


func _emit(f, kind: String, pos: Vector3, dir: Vector3) -> void:
	var cam: Camera3D = f.get_viewport().get_camera_3d()
	if cam != null and cam.global_position.distance_to(pos) > FAR:
		return
	var root: Node = f.get_parent()
	if root == null:
		return
	if not _pool.has(kind):
		_pool[kind] = []
		_idx[kind] = 0
	var arr: Array = _pool[kind]
	var e: CPUParticles3D
	if arr.size() < int(MAX[kind]):
		e = _make(kind)
		root.add_child(e)
		arr.append(e)
	else:
		var i: int = int(_idx[kind])
		_idx[kind] = (i + 1) % arr.size()
		e = arr[i]
		if not is_instance_valid(e):
			e = _make(kind)
			root.add_child(e)
			arr[i] = e
	if e.get_parent() != root:
		e.reparent(root)
	e.global_position = pos
	e.direction = dir
	e.restart()
	e.emitting = true


func _c(f, name: String) -> Array:
	if _consts.is_empty():
		_consts = f.get_script().get_script_constant_map()
	return _consts.get(name, [1.4, 0.9, 0.7])


func _meta(f) -> Dictionary:
	if not f.has_meta("fxv"):
		f.set_meta("fxv", {"shots": 0, "air": false, "vy": 0.0})
	return f.get_meta("fxv")


func on_hurt(f, _dmg: int, by, head: bool) -> void:
	var st: int = clampi(int(f.stance), 0, 2)
	var y: float = float(_c(f, "HEAD_Y")[st]) if head else float(_c(f, "BODY_H")[st]) * 0.7
	var d := Vector3.UP
	if by != null and is_instance_valid(by):
		d = (f.global_position - by.global_position).normalized() + Vector3.UP * 0.4
	_emit(f, "blood", f.global_position + Vector3(0.0, y, 0.0), d.normalized())


func on_fire(f) -> void:
	var m: Dictionary = _meta(f)
	m["shots"] = int(m["shots"]) + 1
	var mp: Vector3 = f.muzzle.global_position
	_emit(f, "shell", mp, f.muzzle.global_transform.basis.x + Vector3.UP * 0.6)
	if int(m["shots"]) % 3 == 0:
		_emit(f, "smoke", mp, Vector3.UP)


func update(f, _delta: float) -> void:
	var m: Dictionary = _meta(f)
	var air: bool = not f.is_on_floor()
	if bool(m["air"]) and not air and float(m["vy"]) < -4.5:
		_emit(f, "dust", f.global_position + Vector3(0.0, 0.05, 0.0), Vector3.UP)
	m["air"] = air
	m["vy"] = f.velocity.y
