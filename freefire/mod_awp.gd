extends RefCounted
# PLAGIN (2-akkaunt): AWM/AWP uchun 3D model — freefire/models/guns/awp.glb.
# Yadro fayllarga TEGILMAYDI: har kadr (jang) va lobbi vitrinasida AWM qurolli jangchining
# parts_root ichidagi modelni shu GLB bilan almashtiradi. awp.glb yoʻq boʻlsa — jim, yadro oʻz modelini koʻrsatadi.
# Model orientatsiyasi: ogʻiz -Z, tepa +Y (gen_awp.py shunday yasaydi). Oʻlcham/markaz GLB dan avtomatik olinadi.
# Skopni yadroning scope_rig.gd i oʻzi tepaga oʻrnatadi (model optikasiz, faqat rail + halqa tayanchlari bor).

const PATH := "res://freefire/models/guns/awp.glb"
const NAMES: Array = ["AWM", "AWP"]
const LEN := 1.15  # yadro GUN_LEN["sniper"] bilan bir xil

var g
var wlist: Array = []
var scene: PackedScene = null
var fit_ok: bool = false
var fit_s: float = 1.0
var fit_c: Vector3 = Vector3.ZERO
var next_try: int = 0
var timer: Timer


func setup(game) -> void:
	g = game


func _weapons() -> bool:
	if not wlist.is_empty():
		return true
	var sc = load("res://freefire/weapons.gd")
	if sc == null:
		return false
	var cm: Dictionary = sc.get_script_constant_map()
	if cm.has("W") and cm["W"] is Array:
		wlist = cm["W"]
	return not wlist.is_empty()


func _assets() -> bool:
	if scene != null:
		return true
	var now: int = Time.get_ticks_msec()
	if now < next_try:
		return false
	next_try = now + 5000  # assets.pck keyinroq kelishi mumkin: har 5 soniyada qayta urinadi
	if not ResourceLoader.exists(PATH):
		return false
	var sc = load(PATH)
	if sc is PackedScene:
		scene = sc
	return scene != null


func _xf_to(n: Node, root: Node) -> Transform3D:
	var t: Transform3D = Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


func _fit(inst: Node3D, meshes: Array) -> void:
	var box: AABB = AABB()
	var first: bool = true
	for m in meshes:
		if m.mesh == null:
			continue
		var a: AABB = _xf_to(m, inst) * m.get_aabb()
		box = a if first else box.merge(a)
		first = false
	if first:
		return
	fit_s = LEN / maxf(box.size.z, 0.0001)
	fit_c = box.get_center()
	fit_ok = true


func _apply(f) -> void:
	if f == null or not is_instance_valid(f):
		return
	if not ("parts_root" in f) or not ("wid" in f) or not ("muzzle" in f):
		return
	var pr = f.parts_root
	if pr == null or not is_instance_valid(pr) or not _weapons():
		return
	var wi: int = int(f.wid)
	if wi < 0 or wi >= wlist.size() or not NAMES.has(str(wlist[wi]["n"])):
		return
	if pr.has_meta("awp_node"):
		var cur = pr.get_meta("awp_node")
		if is_instance_valid(cur) and cur.get_parent() == pr:
			return
	if not _assets():
		return
	var inst: Node3D = scene.instantiate()
	var meshes: Array = inst.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		inst.free()
		return
	if not fit_ok:
		_fit(inst, meshes)
	if not fit_ok:
		inst.free()
		return
	var holder := Node3D.new()
	holder.add_child(inst)
	inst.scale = Vector3.ONE * fit_s
	inst.position = Vector3(0.0, 0.02, -0.15 * LEN) - fit_c * fit_s
	for ch in pr.get_children():
		pr.remove_child(ch)
		ch.queue_free()
	pr.add_child(holder)
	pr.set_meta("awp_node", holder)
	f.muzzle.position = Vector3(0.0, 0.02, -0.15 * LEN - LEN * 0.5)
	if f.has_method("_attach_scope"):
		f.call_deferred("_attach_scope")


func on_update(_delta) -> void:
	if g == null or not ("fighters" in g):
		return
	for f in g.fighters:
		_apply(f)


func on_lobby_build(lobby, _k) -> void:
	timer = Timer.new()
	timer.wait_time = 0.3
	timer.autostart = true
	timer.timeout.connect(_tick_lobby)
	lobby.add_child(timer)


func _tick_lobby() -> void:
	if g != null and "sc_f" in g and g.sc_f != null:
		_apply(g.sc_f)
