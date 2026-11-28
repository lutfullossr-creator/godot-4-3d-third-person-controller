extends RefCounted
# fx_impact.gd (3-akkaunt): o'q devorga/yerga tekkanda uchqun. Hook: HOOKS_3_impact.md
# Havzali (pool) CPUParticles3D: har o'qqa yangi tugun yaratilmaydi, FPS tejaydi.

const POOL: int = 10
const MAX_DIST: float = 70.0

var _pool: Array = []
var _next: int = 0
var _mesh: Mesh = null
var _mat: StandardMaterial3D = null


func _ensure(parent: Node) -> bool:
	if parent == null or not is_instance_valid(parent):
		return false
	if not _pool.is_empty():
		var first: Variant = _pool[0]
		if is_instance_valid(first):
			var fp: Node = first
			if fp.is_inside_tree() and fp.get_parent() == parent:
				return true
		for p in _pool:
			if is_instance_valid(p):
				var old: Node = p
				old.queue_free()
		_pool.clear()
		_next = 0
	if _mesh == null:
		var s := SphereMesh.new()
		s.radius = 0.015
		s.height = 0.03
		s.radial_segments = 4
		s.rings = 2
		_mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.75, 0.3)
		_mat = m
	for i in range(POOL):
		var cp := CPUParticles3D.new()
		cp.emitting = false
		cp.one_shot = true
		cp.amount = 8
		cp.lifetime = 0.25
		cp.explosiveness = 1.0
		cp.mesh = _mesh
		cp.material_override = _mat
		cp.direction = Vector3.UP
		cp.spread = 55.0
		cp.initial_velocity_min = 2.0
		cp.initial_velocity_max = 5.0
		cp.gravity = Vector3(0.0, -9.0, 0.0)
		cp.local_coords = false
		cp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(cp)
		_pool.append(cp)
	return true


func on_impact(f: Object, pos: Vector3, normal: Vector3) -> void:
	if not (f is Node3D):
		return
	var fn: Node3D = f
	if not fn.is_inside_tree():
		return
	var cam: Camera3D = fn.get_viewport().get_camera_3d()
	if cam != null and cam.global_position.distance_to(pos) > MAX_DIST:
		return
	if not _ensure(fn.get_parent()):
		return
	var v: Variant = _pool[_next]
	_next = (_next + 1) % POOL
	if not is_instance_valid(v):
		return
	var cp: CPUParticles3D = v
	cp.global_position = pos + normal * 0.03
	cp.direction = normal
	cp.restart()
