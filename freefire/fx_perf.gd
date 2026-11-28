extends RefCounted
# fx_perf.gd (3-akkaunt): FPS. Uzoqdagi botlarning soyasini o'chiradi.
# FPS past bo'lsa chegara yaqinlashadi (45 m -> 28 m -> 14 m). Yadro fayllarga tegmaydi.

const CHECK_T: float = 0.5
const LIM_OK: float = 45.0
const LIM_MID: float = 28.0
const LIM_LOW: float = 14.0
const HYST: float = 4.0

var _sh: Dictionary = {}
var _t: Dictionary = {}


func on_character(f: Object) -> void:
	# model almashdi: yangi mesh'lar soyasi qayta qo'llanadi
	var id: int = f.get_instance_id()
	_sh.erase(id)
	_t.erase(id)


func update(f: Object, delta: float) -> void:
	if not (f is Node3D):
		return
	if not bool(f.get("is_bot")):
		return
	var id: int = f.get_instance_id()
	var t: float = float(_t.get(id, randf() * CHECK_T)) - delta
	if t > 0.0:
		_t[id] = t
		return
	_t[id] = CHECK_T
	var fn: Node3D = f
	if not fn.is_inside_tree():
		return
	var cam: Camera3D = fn.get_viewport().get_camera_3d()
	if cam == null:
		return
	var fps: float = Engine.get_frames_per_second()
	var lim: float = LIM_OK
	if fps < 35.0:
		lim = LIM_LOW
	elif fps < 50.0:
		lim = LIM_MID
	var was: bool = bool(_sh.get(id, true))
	var d: float = fn.global_position.distance_to(cam.global_position)
	var near: bool = d < (lim + HYST if was else lim - HYST)
	if near == was and _sh.has(id):
		return
	_sh[id] = near
	if _sh.size() > 64:
		_sh.clear()
		_t.clear()
	_set_shadow(fn, near)


func _set_shadow(fn: Node3D, on: bool) -> void:
	var v: Variant = fn.get("vis")
	if not (v is Node):
		return
	var mode: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not on:
		mode = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var vn: Node = v
	for n in vn.find_children("*", "GeometryInstance3D", true, false):
		var gi: GeometryInstance3D = n
		gi.cast_shadow = mode
