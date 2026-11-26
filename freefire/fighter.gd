extends CharacterBody3D

const WeaponDB = preload("res://freefire/weapons.gd")
const SPEED := [5.0, 2.4, 1.0]
const BODY_H := [1.4, 0.9, 0.7]
const HEAD_Y := [1.6, 1.1, 0.62]

const RELOAD_NAME := {
	"ar": "reload_ar", "smg": "reload_ar", "lmg": "reload_ar", "sniper": "reload_ar",
	"pistol": "reload_pistol", "shotgun": "shotgun_cock",
}
static var _snd_cache := {}
static var _fit_cache := {}

# Haqiqiy 3D qurol modellari (FBX + tekstura). Fayl boʻlmasa, oddiy model ishlatiladi.
const MODELS := {
	"AK47": {"path": "res://freefire/models/SKM_AK47.fbx", "tex": "res://freefire/models/T_AK47_", "len": 0.95},
	"M700": {"path": "res://freefire/models/SKM_M700.fbx", "tex": "res://freefire/models/T_M700_", "len": 1.12},
}
const MODEL_FOR := {"M4A1": "AK47", "AK47": "AK47", "SCAR": "AK47", "AWM": "M700", "KAR98K": "M700"}

static var _fx_mods: Array = []
static var _fx_loaded := false
static var _fx_bad: Array = []
static var _guns_files: Array = []
static var _guns_scanned := false
static var _extra := {}
const GUN_LEN := {"ar": 0.95, "smg": 0.62, "shotgun": 1.0, "sniper": 1.15, "lmg": 1.05, "pistol": 0.26}
const GUN_KEYS := {
	"ar": ["ak", "rifle", "assault", "m4", "scar"],
	"smg": ["smg", "mp5", "ump", "vector", "p90", "uzi", "submachine"],
	"sniper": ["sniper", "awm", "kar", "m82", "sks", "bolt"],
	"shotgun": ["shotgun", "spas", "m1887", "m590", "pump"],
	"pistol": ["pistol", "usp", "eagle", "revolver", "glock", "handgun"],
	"lmg": ["lmg", "machine", "m249", "minigun", "heavy"],
}


static func fx_list() -> Array:
	if _fx_loaded:
		return _fx_mods
	_fx_loaded = true
	var names: Array = []
	for fn in DirAccess.get_files_at("res://freefire"):
		var n: String = fn.trim_suffix(".remap").trim_suffix(".import")
		if n.begins_with("fx_") and n.ends_with(".gd") and not names.has(n):
			names.append(n)
	names.sort()
	for n in names:
		var sc = load("res://freefire/" + n)
		if sc != null and sc.can_instantiate():
			_fx_mods.append(sc.new())
		else:
			_fx_bad.append(n)
	if not _fx_bad.is_empty():
		Engine.set_meta("zona_fxbad", ", ".join(_fx_bad))
	return _fx_mods


func _fx_call(fn: String, args: Array) -> void:
	for m in fx_list():
		if m.has_method(fn):
			m.callv(fn, args)


static func _scan_guns() -> void:
	if _guns_scanned:
		return
	_guns_scanned = true
	if not DirAccess.dir_exists_absolute("res://freefire/models/guns"):
		return
	var out: Array = []
	for fn in DirAccess.get_files_at("res://freefire/models/guns"):
		var n: String = fn.trim_suffix(".remap").trim_suffix(".import")
		if (n.ends_with(".glb") or n.ends_with(".gltf") or n.ends_with(".fbx")) and not out.has(n):
			out.append(n)
	_guns_files = out


static func _plain(s: String) -> String:
	var r := ""
	for ch in s.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			r += ch
	return r


static func guns_key(w: Dictionary) -> String:
	_scan_guns()
	if _guns_files.is_empty():
		return ""
	var nm := _plain(str(w["n"]))
	var pick := ""
	for fl in _guns_files:
		var st := _plain(str(fl).get_basename())
		if st.length() >= 2 and (st.contains(nm) or nm.contains(st)):
			pick = str(fl)
			break
	if pick == "":
		for kw in GUN_KEYS.get(str(w["s"]), []):
			for fl in _guns_files:
				if _plain(str(fl).get_basename()).contains(str(kw)):
					pick = str(fl)
					break
			if pick != "":
				break
	if pick == "":
		return ""
	var key := "G:" + pick + ":" + str(w["s"])
	_extra[key] = {"path": "res://freefire/models/guns/" + pick, "tex": "", "len": GUN_LEN.get(str(w["s"]), 0.9)}
	return key


const DK := Color(0.1, 0.1, 0.11)
const MT := Color(0.32, 0.32, 0.34)
const WD := Color(0.42, 0.27, 0.13)
# qurol modellari: [olcham, joy, rang], "m" = ogʻiz uzunligi (z)
const GUNS := {
	"ar": {"m": -0.62, "p": [
		[Vector3(0.06, 0.09, 0.45), Vector3(0, 0, -0.2), DK],
		[Vector3(0.03, 0.03, 0.28), Vector3(0, 0.01, -0.5), MT],
		[Vector3(0.05, 0.1, 0.22), Vector3(0, -0.01, 0.14), WD],
		[Vector3(0.045, 0.2, 0.07), Vector3(0, -0.14, -0.18), MT],
		[Vector3(0.04, 0.04, 0.1), Vector3(0, 0.07, -0.2), DK]]},
	"smg": {"m": -0.42, "p": [
		[Vector3(0.06, 0.09, 0.32), Vector3(0, 0, -0.12), DK],
		[Vector3(0.025, 0.025, 0.18), Vector3(0, 0.01, -0.34), MT],
		[Vector3(0.04, 0.2, 0.05), Vector3(0, -0.14, -0.1), MT],
		[Vector3(0.04, 0.1, 0.05), Vector3(0, -0.1, 0.02), DK]]},
	"shotgun": {"m": -0.82, "p": [
		[Vector3(0.06, 0.08, 0.4), Vector3(0, 0, -0.1), DK],
		[Vector3(0.035, 0.035, 0.6), Vector3(0, 0.01, -0.5), MT],
		[Vector3(0.06, 0.06, 0.2), Vector3(0, -0.04, -0.4), WD],
		[Vector3(0.05, 0.09, 0.25), Vector3(0, -0.01, 0.2), WD]]},
	"sniper": {"m": -1.1, "p": [
		[Vector3(0.06, 0.09, 0.5), Vector3(0, 0, -0.15), DK],
		[Vector3(0.03, 0.03, 0.75), Vector3(0, 0.01, -0.75), MT],
		[Vector3(0.05, 0.05, 0.3), Vector3(0, 0.09, -0.2), DK],
		[Vector3(0.06, 0.11, 0.3), Vector3(0, -0.01, 0.22), WD],
		[Vector3(0.04, 0.08, 0.06), Vector3(0, -0.08, -0.1), MT]]},
	"lmg": {"m": -0.8, "p": [
		[Vector3(0.07, 0.1, 0.5), Vector3(0, 0, -0.15), DK],
		[Vector3(0.03, 0.03, 0.4), Vector3(0, 0.01, -0.6), MT],
		[Vector3(0.12, 0.14, 0.14), Vector3(0, -0.15, -0.12), MT],
		[Vector3(0.05, 0.1, 0.25), Vector3(0, 0, 0.16), DK]]},
	"pistol": {"m": -0.17, "p": [
		[Vector3(0.045, 0.06, 0.2), Vector3(0, 0, -0.05), MT],
		[Vector3(0.04, 0.12, 0.06), Vector3(0, -0.08, 0.03), DK]]},
}

signal hit_info(attacker, target, dmg, head)
signal died(f)

var team := 0
var is_bot := true
var hp := 200
var wid := 0:
	set(v):
		wid = v
		_build_gun()
var mag := 30
var cd := 0.0
var rl := 0.0
var stance := 0
var last_stance := -1
var yaw := 0.0
var pitch := 0.0
var alive := true
var move_input := Vector2.ZERO
var want_fire := false
var want_jump := false
var aim_dir := Vector3(0, 0, -1)
var origin_override := Vector3.ZERO
var use_origin := false
var ai_t := 0.0
var ai_strafe := 0.0
var ai_head := false
var kick := 0.0
var flash_t := 0.0
var step_t := 0.0
var walk_t := 0.0
var pool: Array = []
var pool_i := 0
var body_col: CollisionShape3D
var head_col: CollisionShape3D
var head_area: Area3D
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var rig: Node3D
var gun_root: Node3D
var parts_root: Node3D
var muzzle: Node3D
var flash_light: OmniLight3D
var flash_mesh: MeshInstance3D
var vis: Node3D
var leg_l: Node3D
var leg_r: Node3D
var anim_t := 0.0
var sprint_blend := 0.0
var air_t := 0.0
var sprint := false
var death_tw: Tween
var slot := 0
var slot_wid := [0, 11]
var slot_mag := [30, 12]
var slot_res := [150, 60]
var fired_t := 0.0


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


func _glow(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box_mesh(size: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	return m


func setup(t: int, bot: bool) -> void:
	team = t
	is_bot = bot
	collision_layer = 2
	collision_mask = 1
	var col := Color(0.2, 0.45, 0.9) if t == 0 else Color(0.85, 0.2, 0.2)
	if not bot:
		col = Color(1.0, 0.55, 0.1)
	var cs := CapsuleShape3D.new()
	cs.radius = 0.35
	cs.height = 1.4
	body_col = CollisionShape3D.new()
	body_col.shape = cs
	add_child(body_col)
	vis = Node3D.new()
	add_child(vis)
	var v_shirt := _mat(col)
	var v_pants := _mat(Color(0.14, 0.15, 0.2))
	var v_torso := _box_mesh(Vector3(0.46, 0.62, 0.26), v_shirt)
	v_torso.position = Vector3(0.0, 1.16, 0.0)
	vis.add_child(v_torso)
	var v_hips := _box_mesh(Vector3(0.44, 0.2, 0.25), v_pants)
	v_hips.position = Vector3(0.0, 0.84, 0.0)
	vis.add_child(v_hips)
	leg_l = Node3D.new()
	leg_l.position = Vector3(-0.12, 0.8, 0.0)
	vis.add_child(leg_l)
	var v_ll := _box_mesh(Vector3(0.18, 0.8, 0.2), v_pants)
	v_ll.position = Vector3(0.0, -0.4, 0.0)
	leg_l.add_child(v_ll)
	leg_r = Node3D.new()
	leg_r.position = Vector3(0.12, 0.8, 0.0)
	vis.add_child(leg_r)
	var v_lr := _box_mesh(Vector3(0.18, 0.8, 0.2), v_pants)
	v_lr.position = Vector3(0.0, -0.4, 0.0)
	leg_r.add_child(v_lr)
	head_area = Area3D.new()
	head_area.collision_layer = 4
	head_area.collision_mask = 0
	head_area.monitoring = false
	head_col = CollisionShape3D.new()
	var hs := SphereShape3D.new()
	hs.radius = 0.22
	head_col.shape = hs
	head_area.add_child(head_col)
	add_child(head_area)
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	head_mesh = MeshInstance3D.new()
	head_mesh.mesh = sm
	head_mesh.material_override = _mat(Color(0.9, 0.72, 0.55))
	head_mesh.position = Vector3(0.0, 1.6, 0.0)
	vis.add_child(head_mesh)
	# qurol va qoʻllar
	rig = Node3D.new()
	add_child(rig)
	gun_root = Node3D.new()
	rig.add_child(gun_root)
	parts_root = Node3D.new()
	gun_root.add_child(parts_root)
	var skin := _mat(col.darkened(0.15))
	var arm_r := _box_mesh(Vector3(0.09, 0.09, 0.5), skin)
	arm_r.position = Vector3(0.04, -0.03, 0.22)
	arm_r.rotation_degrees.y = -8.0
	gun_root.add_child(arm_r)
	var arm_l := _box_mesh(Vector3(0.09, 0.09, 0.55), skin)
	arm_l.position = Vector3(-0.1, -0.03, -0.1)
	arm_l.rotation_degrees.y = 18.0
	gun_root.add_child(arm_l)
	muzzle = Node3D.new()
	gun_root.add_child(muzzle)
	flash_mesh = MeshInstance3D.new()
	var fs := SphereMesh.new()
	fs.radius = 0.09
	fs.height = 0.18
	flash_mesh.mesh = fs
	flash_mesh.material_override = _glow(Color(1.0, 0.75, 0.25))
	muzzle.add_child(flash_mesh)
	flash_light = OmniLight3D.new()
	flash_light.light_color = Color(1.0, 0.7, 0.3)
	flash_light.light_energy = 4.0
	flash_light.omni_range = 6.0
	muzzle.add_child(flash_light)
	flash_mesh.visible = false
	flash_light.visible = false
	# ovoz havzasi
	for i in range(6):
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 14.0
		p.max_distance = 150.0
		add_child(p)
		pool.append(p)
	apply_stance()
	_build_gun()


static func synth(sname: String):
	var ck := "syn_" + sname
	if _snd_cache.has(ck):
		return _snd_cache[ck]
	var rate := 22050
	var n := 0
	var data := PackedByteArray()
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	if sname == "step":
		n = 2600
		data.resize(n * 2)
		var lp := 0.0
		for i in range(n):
			var t := float(i) / float(n)
			lp = lp * 0.85 + (randf() * 2.0 - 1.0) * 0.15
			data.encode_s16(i * 2, int(clampf(lp * exp(-t * 7.0) * 2.4, -1.0, 1.0) * 30000.0))
	elif sname == "ui":
		n = 2000
		data.resize(n * 2)
		for i in range(n):
			var t2 := float(i) / float(n)
			var v2 := sin(TAU * 1150.0 * float(i) / float(rate)) * exp(-t2 * 8.0) * 0.5
			data.encode_s16(i * 2, int(clampf(v2, -1.0, 1.0) * 30000.0))
	elif sname == "dry":
		n = 1500
		data.resize(n * 2)
		for i in range(n):
			var t3 := float(i) / float(n)
			var v3 := (randf() * 2.0 - 1.0) * exp(-t3 * 14.0) * 0.6
			data.encode_s16(i * 2, int(clampf(v3, -1.0, 1.0) * 30000.0))
	elif sname == "music":
		rate = 11025
		var seg := rate * 2
		var chords := [[110.0, 130.81, 164.81], [87.31, 130.81, 174.61], [130.81, 164.81, 196.0], [98.0, 146.83, 196.0]]
		n = seg * 4
		data.resize(n * 2)
		for i in range(n):
			var ci: int = i / seg
			var tt := float(i % seg) / float(seg)
			var env := sin(PI * tt)
			var tm := float(i) / float(rate)
			var v4 := 0.0
			for fr in chords[ci]:
				v4 += sin(TAU * float(fr) * tm) + 0.4 * sin(TAU * float(fr) * 2.0 * tm)
			v4 *= env * 0.1 * (0.85 + 0.15 * sin(TAU * 0.25 * tm))
			data.encode_s16(i * 2, int(clampf(v4, -1.0, 1.0) * 30000.0))
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = n
	else:
		return null
	s.mix_rate = rate
	s.data = data
	_snd_cache[ck] = s
	return s


func _snd(sname: String, fallback: String = "") -> AudioStream:
	if not _snd_cache.has(sname):
		var res = null
		for ext in [".ogg", ".wav"]:
			var p := "res://freefire/audio/%s%s" % [sname, ext]
			if ResourceLoader.exists(p):
				res = load(p)
				break
		if res == null:
			res = synth(sname)
		_snd_cache[sname] = res
	var r = _snd_cache[sname]
	if r == null and fallback != "":
		return _snd(fallback)
	return r


func _tex(path: String):
	return load(path) if ResourceLoader.exists(path) else null


func _gun_material(base: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var c = _tex(base + "C.png")
	if c != null:
		m.albedo_texture = c
	var n = _tex(base + "N.png")
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
	var r = _tex(base + "RMAO.png")
	if r != null:
		m.roughness_texture = r
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.metallic = 1.0
		m.metallic_texture = r
		m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.ao_enabled = true
		m.ao_texture = r
		m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	return m


func _collect_meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect_meshes(c, out)


func _xform_to(n: Node, root: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


# Modelni avtomatik joylashtirish: oʻlcham, ogʻiz yoʻnalishi (-Z) va tepa tomon (+Y)
func _compute_fit(holder: Node3D, inst: Node3D, meshes: Array, info: Dictionary) -> Dictionary:
	inst.transform = Transform3D.IDENTITY
	var box := AABB()
	var first := true
	for m in meshes:
		if m.mesh == null:
			continue
		var a: AABB = _xform_to(m, holder) * m.get_aabb()
		box = a if first else box.merge(a)
		first = false
	var size := box.size
	var ax := 0
	if size.y > size[ax]:
		ax = 1
	if size.z > size[ax]:
		ax = 2
	var hx := 1 if ax != 1 else 0
	var other := 3 - ax - hx
	if size[other] > size[hx]:
		hx = other
	# ogʻirlik markazi (ogʻiz va tepa tomonni taxmin qilish uchun)
	var sum_a := 0.0
	var sum_h := 0.0
	var cnt := 0
	for m in meshes:
		if m.mesh == null:
			continue
		var t := _xform_to(m, holder)
		var faces: PackedVector3Array = m.mesh.get_faces()
		var step := maxi(1, faces.size() / 4000)
		var i := 0
		while i < faces.size():
			var v: Vector3 = t * faces[i]
			sum_a += v[ax]
			sum_h += v[hx]
			cnt += 1
			i += step
	var frac_a := 0.5
	var frac_h := 0.5
	if cnt > 0 and size[ax] > 0.0 and size[hx] > 0.0:
		frac_a = (sum_a / cnt - box.position[ax]) / size[ax]
		frac_h = (sum_h / cnt - box.position[hx]) / size[hx]
	var e_a := Vector3.ZERO
	e_a[ax] = 1.0
	var e_h := Vector3.ZERO
	e_h[hx] = 1.0
	var u_mz := e_a if frac_a < 0.5 else -e_a
	var u_up := e_h if frac_h < 0.5 else -e_h
	var z_dir := -u_mz
	var y_dir := u_up
	var x_dir := y_dir.cross(z_dir)
	var rot := Basis(x_dir, y_dir, z_dir).transposed()
	var length: float = info["len"]
	var sc := length / maxf(size[ax], 0.0001)
	var b: Basis = rot * sc
	var target := Vector3(0.0, 0.02, -0.15 * length)
	var origin := target - b * box.get_center()
	return {"xf": Transform3D(b, origin), "muzzle": Vector3(0.0, 0.02, target.z - length * 0.5)}


func _make_model(key: String):
	var info: Dictionary = MODELS[key] if MODELS.has(key) else _extra[key]
	if not ResourceLoader.exists(info["path"]):
		return null
	var scene = load(info["path"])
	if not (scene is PackedScene):
		return null
	var inst: Node3D = scene.instantiate()
	var holder := Node3D.new()
	holder.add_child(inst)
	var meshes: Array = []
	_collect_meshes(inst, meshes)
	if meshes.is_empty():
		holder.free()
		return null
	if str(info["tex"]) != "":
		var mat := _gun_material(info["tex"])
		for m in meshes:
			m.material_override = mat
	if not _fit_cache.has(key):
		_fit_cache[key] = _compute_fit(holder, inst, meshes, info)
	var f: Dictionary = _fit_cache[key]
	inst.transform = f["xf"]
	return {"node": holder, "muzzle": f["muzzle"]}


func _build_gun() -> void:
	if parts_root == null:
		return
	for c in parts_root.get_children():
		c.queue_free()
	var mk: String = MODEL_FOR.get(WeaponDB.W[wid]["n"], "")
	if mk == "":
		mk = guns_key(WeaponDB.W[wid])
	if mk != "":
		var mdl = _make_model(mk)
		if mdl != null:
			parts_root.add_child(mdl["node"])
			muzzle.position = mdl["muzzle"]
			return
	var g: Dictionary = GUNS[WeaponDB.W[wid]["s"]]
	for p in g["p"]:
		var m := _box_mesh(p[0], _mat(p[2]))
		m.position = p[1]
		parts_root.add_child(m)
	muzzle.position = Vector3(0, 0.01, g["m"])


func head_y() -> float:
	return HEAD_Y[stance]


func eye() -> Vector3:
	return global_position + Vector3(0.0, HEAD_Y[stance], 0.0)


func aim_point(head: bool) -> Vector3:
	return head_area.global_position if head else body_col.global_position


func give(i: int) -> void:
	var alt := 11 if i != 11 else 12
	slot = 0
	slot_wid = [i, alt]
	slot_mag = [WeaponDB.W[i]["mag"], WeaponDB.W[alt]["mag"]]
	slot_res = [int(WeaponDB.W[i]["mag"]) * 5, int(WeaponDB.W[alt]["mag"]) * 5]
	rl = 0.0
	wid = i
	mag = slot_mag[0]


func swap() -> void:
	if not alive or rl > 0.0:
		return
	slot_mag[slot] = mag
	slot = 1 - slot
	wid = slot_wid[slot]
	mag = slot_mag[slot]
	cd = 0.3


func apply_stance() -> void:
	var cs := body_col.shape as CapsuleShape3D
	if stance == 2:
		cs.radius = 0.3
		cs.height = 1.6
		body_col.rotation.x = PI * 0.5
		body_col.position = Vector3(0.0, 0.3, -0.7)
		head_area.position = Vector3(0.0, 0.32, -1.5)
	else:
		var h: float = BODY_H[stance]
		cs.radius = 0.35
		cs.height = h
		body_col.rotation.x = 0.0
		body_col.position = Vector3(0.0, h * 0.5, 0.0)
		head_area.position = Vector3(0.0, HEAD_Y[stance], 0.0)
	rig.position = Vector3(0.0, HEAD_Y[stance] - 0.35, 0.0)


func _play(s: AudioStream, db: float = 0.0, pv: float = 0.05) -> void:
	if s == null or pool.is_empty():
		return
	var p: AudioStreamPlayer3D = pool[pool_i]
	pool_i = (pool_i + 1) % pool.size()
	p.stream = s
	p.volume_db = db
	p.pitch_scale = 1.0 + randf_range(-pv, pv)
	p.play()


func _fx(pos: Vector3, col: Color, size: float, life: float) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = size
	s.height = size * 2.0
	m.mesh = s
	m.material_override = _glow(col)
	get_parent().add_child(m)
	m.global_position = pos
	get_tree().create_timer(life).timeout.connect(m.queue_free)


func _tracer(a: Vector3, b: Vector3) -> void:
	var l := a.distance_to(b)
	if l < 0.6:
		return
	var dir := (b - a).normalized()
	var shown := minf(l, 40.0)
	var m := _box_mesh(Vector3(0.025, 0.025, shown), _glow(Color(1.0, 0.9, 0.5)))
	get_parent().add_child(m)
	var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT
	m.look_at_from_position(a + dir * shown * 0.5, b, up)
	get_tree().create_timer(0.05).timeout.connect(m.queue_free)


func reset(pos: Vector3, y: float) -> void:
	global_position = pos
	yaw = y
	pitch = 0.0
	hp = 200
	alive = true
	visible = true
	stance = 0
	last_stance = 0
	velocity = Vector3.ZERO
	cd = 0.0
	rl = 0.0
	kick = 0.0
	move_input = Vector2.ZERO
	want_fire = false
	want_jump = false
	body_col.disabled = false
	head_col.disabled = false
	if death_tw != null:
		death_tw.kill()
	sprint = false
	vis.rotation.x = 0.0
	vis.position.y = 0.0
	vis.scale = Vector3.ONE
	leg_l.rotation.x = 0.0
	leg_r.rotation.x = 0.0
	rig.visible = true
	apply_stance()


func reload() -> void:
	if rl <= 0.0 and mag < WeaponDB.W[wid]["mag"] and (is_bot or int(slot_res[slot]) > 0):
		rl = WeaponDB.W[wid]["rl"]
		_play(_snd(RELOAD_NAME[WeaponDB.W[wid]["s"]], "reload"), -4.0, 0.02)


func hurt(dmg: int, by, head: bool) -> void:
	if not alive:
		return
	hp -= dmg
	_fx_call("on_hurt", [self, dmg, by, head])
	_play(_snd("headshot") if head else _snd("hit"), -6.0 if is_bot else -2.0, 0.03)
	hit_info.emit(by, self, dmg, head)
	if hp <= 0:
		hp = 0
		alive = false
		_play(_snd("death"), -2.0, 0.05)
		body_col.set_deferred("disabled", true)
		head_col.set_deferred("disabled", true)
		rig.visible = false
		died.emit(self)
		_die_anim()


func _die_anim() -> void:
	death_tw = create_tween()
	death_tw.tween_property(vis, "rotation:x", PI * 0.5, 0.5)
	await get_tree().create_timer(2.5).timeout
	if not alive:
		visible = false


func try_fire() -> void:
	if cd > 0.0 or rl > 0.0:
		return
	var w: Dictionary = WeaponDB.W[wid]
	if mag <= 0:
		_play(_snd("dry"), -6.0, 0.02)
		cd = 0.3
		reload()
		return
	mag -= 1
	fired_t = 1.6
	_fx_call("on_fire", [self])
	cd = w["rate"] * (1.8 if is_bot else 1.0)
	kick = minf(kick + float(w["rc"]), 3.0)
	flash_t = 0.05
	_play(_snd("shot_" + str(w["n"]).to_lower().replace(" ", "_"), "shot_" + str(w["s"])), -1.0, 0.04)
	var from := origin_override if use_origin else eye()
	var space := get_world_3d().direct_space_state
	var mpos := muzzle.global_position
	for i in range(int(w["pel"])):
		var sp: float = w["spread"] * (3.0 if is_bot else 1.0)
		var d := (aim_dir + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * sp).normalized()
		var q := PhysicsRayQueryParameters3D.create(from, from + d * 120.0, 7, [get_rid(), head_area.get_rid()])
		q.collide_with_areas = true
		var r := space.intersect_ray(q)
		if r.is_empty():
			if i < 2:
				_tracer(mpos, from + d * 120.0)
			continue
		var hp_pos: Vector3 = r["position"]
		if i < 2:
			_tracer(mpos, hp_pos)
		var c = r["collider"]
		var tgt = null
		var head := false
		if c is Area3D:
			tgt = c.get_parent()
			head = true
		elif c.has_method("hurt"):
			tgt = c
		if tgt != null and tgt.has_method("hurt"):
			_fx(hp_pos, Color(1.0, 0.2, 0.15), 0.12 if head else 0.08, 0.12)
			if tgt.alive and tgt.team != team:
				var dmg := int(float(w["dmg"]) * (2.4 if head else 1.0) * (0.5 if is_bot else 1.0))
				tgt.hurt(dmg, self, head)
		else:
			_fx(hp_pos + r["normal"] * 0.03, Color(1.0, 0.7, 0.25), 0.06, 0.1)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	if stance != last_stance:
		last_stance = stance
		apply_stance()
	cd -= delta
	fired_t = maxf(fired_t - delta, 0.0)
	if rl > 0.0:
		rl -= delta
		if rl <= 0.0:
			var need: int = int(WeaponDB.W[wid]["mag"]) - mag
			var take: int = need if is_bot else mini(need, int(slot_res[slot]))
			mag += take
			if not is_bot:
				slot_res[slot] = int(slot_res[slot]) - take
	var spd: float = SPEED[stance]
	if sprint and stance == 0:
		spd *= 1.6
	if move_input.length() < 0.1:
		sprint = false
	var dir := Basis(Vector3.UP, yaw) * Vector3(move_input.x, 0.0, move_input.y)
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	if is_on_floor():
		velocity.y = 0.0
		if want_jump and stance == 0:
			velocity.y = 6.5
	else:
		velocity.y -= 20.0 * delta
	want_jump = false
	move_and_slide()
	rotation.y = yaw
	if want_fire:
		try_fire()
	# animatsiya va effektlar
	kick = move_toward(kick, 0.0, delta * 12.0)
	flash_t -= delta
	flash_mesh.visible = flash_t > 0.0
	flash_light.visible = flash_t > 0.0
	var grounded := is_on_floor()
	if grounded:
		if air_t > 0.35:
			_play(_snd("step"), -3.0, 0.1)
		air_t = 0.0
	else:
		air_t += delta
	var moving := move_input.length() > 0.1 and is_on_floor()
	if moving:
		walk_t += delta * (9.0 if stance == 0 else 5.0)
		step_t -= delta
		if step_t <= 0.0 and stance == 0:
			step_t = 0.26 if sprint else 0.34
			_play(_snd("step"), -10.0, 0.12)
	var bob := sin(walk_t) * 0.012 if moving else sin(Time.get_ticks_msec() * 0.002) * 0.004
	var tilt := 0.0
	if rl > 0.0:
		var prog := 1.0 - rl / float(WeaponDB.W[wid]["rl"])
		tilt = -0.75 * sin(clampf(prog, 0.0, 1.0) * PI)
	var vxz := Vector2(velocity.x, velocity.z).length()
	anim_t += delta * (2.0 + vxz * 1.6)
	var amp := clampf(vxz / 5.0, 0.0, 1.0) * (0.95 if stance == 0 else 0.45)
	if is_on_floor():
		leg_l.rotation.x = sin(anim_t) * amp
		leg_r.rotation.x = -sin(anim_t) * amp
	else:
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.9, delta * 12.0)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, -0.5, delta * 12.0)
	var want_rot := 0.0
	var want_y := 0.0
	var want_sy := 1.0
	if stance == 2:
		want_rot = -PI * 0.5
		want_y = 0.2
	elif stance == 1:
		want_sy = 0.66
	vis.rotation.x = lerpf(vis.rotation.x, want_rot, delta * 12.0)
	vis.position.y = lerpf(vis.position.y, want_y, delta * 12.0)
	vis.scale.y = lerpf(vis.scale.y, want_sy, delta * 12.0)
	_char_anim()
	_fx_call("update", [self, delta])
	gun_root.rotation.x = kick * 0.05 + tilt
	gun_root.position = Vector3(0.22, bob, -0.15 + kick * 0.04)


# ---------- tayyor personaj modeli ----------
func set_character(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var ps = load(path)
	if not (ps is PackedScene):
		return
	var m: Node3D = ps.instantiate()
	for c in vis.get_children():
		if c is Node3D:
			c.visible = false
	for c in gun_root.get_children():
		if c is MeshInstance3D and c.mesh is BoxMesh:
			c.visible = false
	vis.add_child(m)
	m.rotation.y = PI
	var mn := Vector3(1e9, 1e9, 1e9)
	var mx := Vector3(-1e9, -1e9, -1e9)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var t: Transform3D = vis.global_transform.affine_inverse() * mi.global_transform
		var a: AABB = t * mi.get_aabb()
		mn = mn.min(a.position)
		mx = mx.max(a.end)
	var h := mx.y - mn.y
	if h > 0.01:
		var s := 1.75 / h
		m.scale = m.scale * s
		m.position = Vector3(-(mn.x + mx.x) * 0.5 * s, -mn.y * s, -(mn.z + mx.z) * 0.5 * s)
	_char_pose(m)
	_fx_call("on_character", [self])


var ch_sk: Skeleton3D = null
var ch_bones := {}


func _char_pose(m: Node3D) -> void:
	for ap in m.find_children("*", "AnimationPlayer", true, false):
		var best_len := 0.0
		var pick := ""
		for n in ap.get_animation_list():
			var an0: Animation = ap.get_animation(n)
			if str(n) != "RESET" and an0 != null and an0.length > best_len:
				best_len = an0.length
				pick = str(n)
		if pick != "" and best_len > 0.5:
			var an: Animation = ap.get_animation(pick)
			an.loop_mode = Animation.LOOP_LINEAR
			ap.play(pick)
			return
	for skv in m.find_children("*", "Skeleton3D", true, false):
		var sk: Skeleton3D = skv
		ch_sk = sk
		ch_bones = {}
		var keys := ["leftarm", "leftforearm", "lefthand", "rightarm", "rightforearm", "righthand", "leftupleg", "leftleg", "leftfoot", "rightupleg", "rightleg", "rightfoot", "spine1", "head"]
		for i in range(sk.get_bone_count()):
			var nm: String = sk.get_bone_name(i).to_lower()
			for key in keys:
				if nm.ends_with(key) and not ch_bones.has(key):
					ch_bones[key] = i
		if ch_bones.size() < 6:
			ch_sk = null
		return


func _set_abs(i: int, g: Basis) -> void:
	var par := ch_sk.get_bone_parent(i)
	var pg := Basis.IDENTITY
	if par >= 0:
		pg = ch_sk.get_bone_global_pose(par).basis
	ch_sk.set_bone_pose_rotation(i, (pg.inverse() * g).orthonormalized().get_rotation_quaternion())


func _point_bone(a: String, b: String, target: Vector3) -> void:
	if not ch_bones.has(a) or not ch_bones.has(b):
		return
	var i: int = ch_bones[a]
	var j: int = ch_bones[b]
	var gi := ch_sk.get_bone_global_rest(i)
	var gj := ch_sk.get_bone_global_rest(j)
	var rd := (gj.origin - gi.origin).normalized()
	var td := target.normalized()
	if rd.dot(td) < -0.99:
		return
	_set_abs(i, Basis(Quaternion(rd, td)) * gi.basis)


func _turn_bone(key: String, ang: float) -> void:
	if not ch_bones.has(key):
		return
	var i: int = ch_bones[key]
	_set_abs(i, Basis(Vector3.RIGHT, ang) * ch_sk.get_bone_global_rest(i).basis)


func lobby_pose() -> void:
	gun_root.position = Vector3(0.22, 0.0, -0.15)
	gun_root.rotation.x = 0.0
	_char_anim(true)


func _char_anim(force_ground: bool = false) -> void:
	if ch_sk == null:
		return
	var spd := Vector2(velocity.x, velocity.z).length()
	var run := clampf(spd / 5.0, 0.0, 1.0)
	var spr := 1.0 if (sprint and spd > 2.0) else 0.0
	sprint_blend = lerpf(sprint_blend, spr, 0.15)
	var breathe := sin(Time.get_ticks_msec() * 0.0022) * 0.015
	var lean := run * 0.07 + sprint_blend * 0.14 + kick * 0.04 - pitch * 0.2 + breathe
	_turn_bone("spine1", lean)
	_turn_bone("head", -pitch * 0.55 - lean * 0.6)
	var rlp := 0.0
	if rl > 0.0:
		rlp = sin(clampf(1.0 - rl / float(WeaponDB.W[wid]["rl"]), 0.0, 1.0) * PI)
	var armsw := sin(anim_t) * run * 0.08
	var rec := kick * 0.35
	var low := sprint_blend * 0.35
	_point_bone("leftarm", "leftforearm", Vector3(-0.25 + 0.2 * rlp, -0.6 - 0.25 * rlp - low, 0.55 - 0.2 * rlp - rec + armsw))
	_point_bone("leftforearm", "lefthand", Vector3(-0.30 + 0.55 * rlp, 0.10 - 0.55 * rlp, 0.95 - 0.5 * rlp - rec))
	_point_bone("rightarm", "rightforearm", Vector3(0.25, -0.6 - low, 0.55 - rec - armsw))
	_point_bone("rightforearm", "righthand", Vector3(0.40, 0.15, 0.90 - rec))
	var air := (not is_on_floor()) and not force_ground
	for side in ["left", "right"]:
		var sw: float = leg_l.rotation.x if side == "left" else leg_r.rotation.x
		var th := -sw
		var bend := maxf(0.0, -sw) * (1.4 + sprint_blend * 0.6)
		if air:
			th -= 0.35
			bend += 0.6
		_turn_bone(side + "upleg", th)
		_turn_bone(side + "leg", th + bend)
		if ch_bones.has(side + "foot"):
			var fi: int = ch_bones[side + "foot"]
			_set_abs(fi, ch_sk.get_bone_global_rest(fi).basis)
