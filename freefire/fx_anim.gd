extends RefCounted
# fx_anim.gd (3-akkaunt). fighter._char_anim ustiga qo'shimcha suyak animatsiyasi.
# Konventsiya (fighter bilan bir xil): skelet fazosida old = +Z, +X atrofida + burchak = oldinga egilish
# (oyoqda esa orqaga siltanish). Faqat ch_sk bor personajda ishlaydi (Ely kabi Mixamo skelet).
# Ishlatadi: f.ch_sk, f.ch_bones, f._point_bone() (fighter.gd, nomini o'zgartirmang).

const EXTRA := {"hips": "hips", "spine": "spine", "spine2": "spine2", "neck": "neck"}


func _by_end(sk: Skeleton3D, key: String) -> int:
	for i in range(sk.get_bone_count()):
		var nm: String = sk.get_bone_name(i).to_lower()
		if nm.ends_with(key):
			return i
	return -1


func on_character(f) -> void:
	if f.has_meta("fxa"):
		f.remove_meta("fxa")
	var sk: Skeleton3D = f.ch_sk
	if sk == null:
		return
	var b := {}
	for k in EXTRA:
		var idx: int = _by_end(sk, str(EXTRA[k]))
		if idx >= 0:
			b[k] = idx
	f.set_meta("fxa", {"b": b, "hurt": 0.0, "head": 0.0, "land": 0.0, "air": false, "vy": 0.0, "cb": 0.0})


func on_hurt(f, dmg: int, _by, head: bool) -> void:
	if not f.has_meta("fxa"):
		return
	var m: Dictionary = f.get_meta("fxa")
	m["hurt"] = clampf(float(dmg) / 35.0, 0.35, 1.0)
	m["head"] = 1.0 if head else 0.0
	if f.hp <= 0 and f.ch_sk != null:
		var tw: Tween = f.create_tween()
		tw.tween_method(Callable(self, "_die_pose").bind(f), 0.0, 1.0, 0.45)


# Global basis berish (ota suyak holatiga nisbatan lokalga o'giriladi).
func _set(sk: Skeleton3D, i: int, g: Basis) -> void:
	var par: int = sk.get_bone_parent(i)
	var pg := Basis.IDENTITY
	if par >= 0:
		pg = sk.get_bone_global_pose(par).basis
	sk.set_bone_pose_rotation(i, (pg.inverse() * g).orthonormalized().get_rotation_quaternion())


# Hozirgi holat ustiga qo'shish (fighter har kadr mutlaq qo'yadigan suyaklar uchun: upleg, leg).
func _add(sk: Skeleton3D, i: int, ang: float) -> void:
	if i < 0 or absf(ang) < 0.0001:
		return
	_set(sk, i, Basis(Vector3.RIGHT, ang) * sk.get_bone_global_pose(i).basis)


# Rest holatdan hisoblash (fighter tegmaydigan suyaklar: hips, spine, spine2, neck), to'planib qolmaydi.
func _rest(sk: Skeleton3D, b: Dictionary, key: String, pitch: float, yaw: float, roll: float) -> void:
	if not b.has(key):
		return
	var i: int = b[key]
	var par: int = sk.get_bone_parent(i)
	var pg := Basis.IDENTITY
	if par >= 0:
		pg = sk.get_bone_global_pose(par).basis
	var base: Basis = pg * sk.get_bone_rest(i).basis
	_set(sk, i, Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.FORWARD, roll) * base)


func update(f, delta: float) -> void:
	if not f.has_meta("fxa"):
		return
	var sk: Skeleton3D = f.ch_sk
	if sk == null or not is_instance_valid(sk):
		return
	var m: Dictionary = f.get_meta("fxa")
	var b: Dictionary = m["b"]
	var air: bool = not f.is_on_floor()
	if bool(m["air"]) and not air:
		m["land"] = clampf(absf(float(m["vy"])) / 9.0, 0.25, 1.0)
	m["air"] = air
	m["vy"] = f.velocity.y
	m["land"] = move_toward(float(m["land"]), 0.0, delta * 3.0)
	m["hurt"] = move_toward(float(m["hurt"]), 0.0, delta * 4.0)
	var tgt: float = 1.0 if (f.stance == 1 and not air) else 0.0
	m["cb"] = lerpf(float(m["cb"]), tgt, minf(delta * 10.0, 1.0))
	var land: float = m["land"]
	var hurt: float = m["hurt"]
	var cb: float = m["cb"]
	var hd: float = m["head"]
	var spd: float = Vector2(f.velocity.x, f.velocity.z).length()
	var run: float = clampf(spd / 5.0, 0.0, 1.0)
	var sw: float = sin(f.anim_t) * run
	var t: float = Time.get_ticks_msec() * 0.001
	var squat: float = clampf(cb * 1.15 + land * 0.5, 0.0, 1.3)
	# tana: o'tirganda/qo'nganda oldinga, yugurganda qarshi burilish, urilganda orqaga silkinish, nafas
	_rest(sk, b, "hips", squat * 0.20, 0.0, 0.0)
	_rest(sk, b, "spine", cb * 0.15 + land * 0.10 - hurt * 0.10, 0.0, 0.0)
	_rest(sk, b, "spine2", -hurt * 0.22, sw * 0.12 + hurt * 0.15, sin(t * 0.9) * 0.012 * (1.0 - run))
	_rest(sk, b, "neck", -hurt * 0.30 * (1.0 + hd), -hurt * 0.12, 0.0)
	# oyoq: cho'kish (sakrashdan keyin ham) — tizza bukiladi, tovon poldan uzilmaydi
	if squat > 0.01:
		var a: float = squat * 0.9
		for side in ["left", "right"]:
			var ul: int = f.ch_bones.get(side + "upleg", -1)
			var lg: int = f.ch_bones.get(side + "leg", -1)
			var fo: int = f.ch_bones.get(side + "foot", -1)
			_add(sk, ul, -a)
			_add(sk, lg, a * 2.0)
			if fo >= 0:
				_set(sk, fo, sk.get_bone_global_rest(fo).basis)
	# eski "vis.scale.y = 0.66" siqilishi o'rniga tizza bukish; tana pastga tushadi (oyoq uzunligi ~0.88 m)
	if f.stance != 2:
		f.vis.scale.y = 1.0
		f.vis.position.y = -0.88 * (1.0 - cos(squat * 0.9))


# O'lish: tizza bukiladi, tana oldinga cho'kadi, qo'llar tushadi. fighter o'lganda _char_anim ni to'xtatadi,
# shuning uchun mutlaq (rest'dan) qo'yamiz.
func _die_pose(p: float, f) -> void:
	var sk: Skeleton3D = f.ch_sk
	if sk == null or not is_instance_valid(sk):
		return
	var cbn: Dictionary = f.ch_bones
	for side in ["left", "right"]:
		if cbn.has(side + "upleg"):
			var ui: int = cbn[side + "upleg"]
			_set(sk, ui, Basis(Vector3.RIGHT, -p * 1.2) * sk.get_bone_global_rest(ui).basis)
		if cbn.has(side + "leg"):
			var li: int = cbn[side + "leg"]
			_set(sk, li, Basis(Vector3.RIGHT, p * 0.8) * sk.get_bone_global_rest(li).basis)
		if cbn.has(side + "foot"):
			var fi: int = cbn[side + "foot"]
			_set(sk, fi, sk.get_bone_global_rest(fi).basis)
	if cbn.has("spine1"):
		var si: int = cbn["spine1"]
		_set(sk, si, Basis(Vector3.RIGHT, p * 0.9) * sk.get_bone_global_rest(si).basis)
	if cbn.has("head"):
		var hi: int = cbn["head"]
		_set(sk, hi, Basis(Vector3.RIGHT, p * 0.5) * sk.get_bone_global_rest(hi).basis)
	if f.has_method("_point_bone"):
		f._point_bone("leftarm", "leftforearm", Vector3(-0.25, -0.6 - 0.4 * p, 0.55 * (1.0 - p) + 0.1))
		f._point_bone("leftforearm", "lefthand", Vector3(-0.2, -1.0, 0.15))
		f._point_bone("rightarm", "rightforearm", Vector3(0.25, -0.6 - 0.4 * p, 0.55 * (1.0 - p) + 0.1))
		f._point_bone("rightforearm", "righthand", Vector3(0.2, -1.0, 0.15))
