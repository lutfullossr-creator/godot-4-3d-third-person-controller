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
var sprint := false
var death_tw: Tween
var slot := 0
var slot_wid := [0, 11]
var slot_mag := [30, 12]


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


func _snd(sname: String, fallback: String = "") -> AudioStream:
	if not _snd_cache.has(sname):
		var res = null
		for ext in [".ogg", ".wav"]:
			var p := "res://freefire/audio/%s%s" % [sname, ext]
			if ResourceLoader.exists(p):
				res = load(p)
				break
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
	var info: Dictionary = MODELS[key]
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
	if rl <= 0.0 and mag < WeaponDB.W[wid]["mag"]:
		rl = WeaponDB.W[wid]["rl"]
		_play(_snd(RELOAD_NAME[WeaponDB.W[wid]["s"]], "reload"), -4.0, 0.02)


func hurt(dmg: int, by, head: bool) -> void:
	if not alive:
		return
	hp -= dmg
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
	if rl > 0.0:
		rl -= delta
		if rl <= 0.0:
			mag = WeaponDB.W[wid]["mag"]
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
	var moving := move_input.length() > 0.1 and is_on_floor()
	if moving:
		walk_t += delta * (9.0 if stance == 0 else 5.0)
		step_t -= delta
		if step_t <= 0.0 and stance == 0:
			step_t = 0.34
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
	gun_root.rotation.x = kick * 0.05 + tilt
	gun_root.position = Vector3(0.22, bob, -0.15 + kick * 0.04)
