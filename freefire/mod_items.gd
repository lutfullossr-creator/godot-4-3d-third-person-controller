extends RefCounted
# PLAGIN: granata, pichoq, dori (medkit).
# Egasi: 1-akkaunt. Faqat shu faylni oʻzgartiring.
# Interfeys: HANDOFF_PLAGINLAR.md

const WeaponDB = preload("res://freefire/weapons.gd")
var g


func setup(game) -> void:
	g = game


func buttons() -> Dictionary:
	return {
		"gren": {"x": 0.575, "y": 0.64, "r": 42.0},
		"med": {"x": 0.47, "y": 0.80, "r": 42.0},
		"knife": {"x": 0.57, "y": 0.45, "r": 40.0},
	}


func draw_icon(n: String, hud: Control, c: Vector2, r: float, col: Color) -> bool:
	var u := r * 0.5
	var w := maxf(3.0, r * 0.09)
	if n == "gren":
		hud.draw_circle(c + Vector2(0, u * 0.25), u * 0.7, col)
		hud.draw_rect(Rect2(c + Vector2(-u * 0.2, -u * 0.8), Vector2(u * 0.4, u * 0.35)), col)
		hud.draw_line(c + Vector2(u * 0.2, -u * 0.65), c + Vector2(u * 0.85, -u * 0.3), col, w)
		return true
	if n == "med":
		hud.draw_rect(Rect2(c + Vector2(-u * 0.85, -u * 0.7), Vector2(u * 1.7, u * 1.4)), col, false, w)
		hud.draw_line(c + Vector2(-u * 0.4, 0), c + Vector2(u * 0.4, 0), col, w * 1.4)
		hud.draw_line(c + Vector2(0, -u * 0.4), c + Vector2(0, u * 0.4), col, w * 1.4)
		return true
	if n == "knife":
		var blade := PackedVector2Array([c + Vector2(-u * 0.9, u * 0.9), c + Vector2(u * 0.7, -u * 0.8), c + Vector2(u * 0.95, -u * 0.5), c + Vector2(-u * 0.4, u * 0.6)])
		hud.draw_colored_polygon(blade, col)
		hud.draw_line(c + Vector2(-u * 0.9, u * 0.9), c + Vector2(-u * 0.5, u * 0.5), col, w * 1.6)
		return true
	return false


func on_btn(n: String) -> bool:
	if n == "gren":
		throw_player()
		return true
	if n == "med":
		use_med(g.player)
		return true
	if n == "knife":
		melee(g.player)
		return true
	return false


func on_key(code: int) -> bool:
	if code == KEY_G:
		throw_player()
		return true
	if code == KEY_H:
		use_med(g.player)
		return true
	if code == KEY_E:
		melee(g.player)
		return true
	return false


func on_round_start(_ri: int) -> bool:
	for f in g.fighters:
		var s: Dictionary = g.inv(f)
		s["gren"] = 2 if g.sel_map != 2 else 0
		s["med"] = 1 if g.sel_map != 2 else 0
		s["heal"] = 0.0
	return false


func on_update(delta: float) -> void:
	for f in g.fighters:
		var s: Dictionary = g.inv(f)
		s["gcd"] = maxf(float(s["gcd"]) - delta, 0.0)
		s["kcd"] = maxf(float(s["kcd"]) - delta, 0.0)
		if float(s["heal"]) > 0.0:
			if not f.alive or f.hp < int(s["hp0"]):
				s["heal"] = 0.0
			else:
				s["heal"] = float(s["heal"]) - delta
				if float(s["heal"]) <= 0.0:
					s["med"] = int(s["med"]) - 1
					f.hp = mini(200, f.hp + 75)


func on_think(b, delta: float) -> bool:
	var t = g._nearest_enemy(b)
	if t == null:
		return false
	var s: Dictionary = g.inv(b)
	var d: float = (t.global_position - b.global_position).length()
	if d < 2.3:
		melee(b)
	elif int(s["gren"]) > 0 and float(s["gcd"]) <= 0.0 and d > 9.0 and d < 28.0 and randf() < delta * 0.12:
		var to: Vector3 = (t.global_position + Vector3(0, 1.0, 0) - b.eye()).normalized()
		throw_grenade(b, to)
	if d > 45.0 and b.hp < 110 and int(s["med"]) > 0:
		use_med(b)
	return false


func draw_hud(hud: Control, vs: Vector2, k: float) -> void:
	var p = g.player
	if p == null:
		return
	var s: Dictionary = g.inv(p)
	var font := ThemeDB.fallback_font
	hud.draw_string(font, Vector2(vs.x - 314.0 * k, 92.0 * k + 170.0 * k), "GRANATA %d     DORI %d" % [int(s["gren"]), int(s["med"])], HORIZONTAL_ALIGNMENT_LEFT, 300.0 * k, int(18.0 * k), Color(1, 1, 1, 0.85))
	if float(s["heal"]) > 0.0:
		var w := 260.0 * k
		var o := Vector2(vs.x * 0.5 - w * 0.5, vs.y - 150.0 * k)
		hud.draw_rect(Rect2(o, Vector2(w, 16.0 * k)), Color(0, 0, 0, 0.6))
		hud.draw_rect(Rect2(o, Vector2(w * (1.0 - float(s["heal"]) / 2.5), 16.0 * k)), Color(0.3, 0.95, 0.4))
		hud.draw_string(font, o + Vector2(0, -6.0 * k), "DAVOLANMOQDA", HORIZONTAL_ALIGNMENT_CENTER, w, int(18.0 * k), Color.WHITE)


func use_med(f) -> void:
	if f == null or not f.alive:
		return
	var s: Dictionary = g.inv(f)
	if int(s["med"]) > 0 and f.hp < 200 and float(s["heal"]) <= 0.0:
		s["heal"] = 2.5
		s["hp0"] = f.hp


func melee(f) -> void:
	if f == null or not f.alive:
		return
	var s: Dictionary = g.inv(f)
	if float(s["kcd"]) > 0.0:
		return
	s["kcd"] = 0.7
	var fw := Vector3(-sin(f.yaw), 0.0, -cos(f.yaw))
	for e in g.fighters:
		if e.team == f.team or not e.alive:
			continue
		var to: Vector3 = e.global_position - f.global_position
		to.y = 0.0
		var d := to.length()
		if d > 0.01 and d < 2.3 and fw.dot(to / d) > 0.35:
			e.hurt(60, f, false)
			break
	_sound(f.global_position, "swish", -2.0)


func throw_player() -> void:
	var p = g.player
	if p == null or not p.alive:
		return
	var dir: Vector3 = Basis.from_euler(Vector3(p.pitch, p.yaw, 0.0)) * Vector3(0, 0, -1)
	throw_grenade(p, dir)


func throw_grenade(f, dir: Vector3) -> void:
	var s: Dictionary = g.inv(f)
	if not f.alive or int(s["gren"]) <= 0 or float(s["gcd"]) > 0.0:
		return
	s["gren"] = int(s["gren"]) - 1
	s["gcd"] = 1.0
	dir.y += 0.18
	dir = dir.normalized()
	var body := RigidBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	body.continuous_cd = true
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.14
	cs.shape = sh
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	mi.mesh = sm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.18, 0.28, 0.16)
	mi.material_override = mt
	body.add_child(mi)
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.35
	pm.friction = 0.8
	body.physics_material_override = pm
	g.add_child(body)
	body.global_position = f.eye() + dir * 0.7
	body.linear_velocity = dir * 17.0 + Vector3(0, 2.0, 0)
	_sound(f.global_position, "swish", -4.0)
	g.get_tree().create_timer(2.4).timeout.connect(_boom.bind(body, f))


func _boom(body, owner) -> void:
	if not is_instance_valid(body):
		return
	var p: Vector3 = body.global_position
	body.queue_free()
	explode(p, owner)


func explode(p: Vector3, owner) -> void:
	var space = g.get_world_3d().direct_space_state
	for fi in g.fighters:
		if not is_instance_valid(fi) or not fi.alive:
			continue
		var c: Vector3 = fi.global_position + Vector3(0, 1.0, 0)
		var d: float = c.distance_to(p)
		if d < 7.0:
			var dmg := int(clampf(130.0 * (1.0 - d / 7.0), 10.0, 130.0))
			var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.3, 0), c, 1)
			if not space.intersect_ray(q).is_empty():
				dmg = int(dmg * 0.4)
			fi.hurt(dmg, owner, false)
	var fx := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.0
	sp.height = 2.0
	fx.mesh = sp
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.6, 0.15, 0.8)
	fx.material_override = m
	g.add_child(fx)
	fx.global_position = p
	fx.scale = Vector3.ONE * 0.5
	var tw := fx.create_tween()
	tw.set_parallel(true)
	tw.tween_property(fx, "scale", Vector3.ONE * 6.0, 0.35)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(fx.queue_free)
	_sound(p, "boom", 4.0)


var _snd := {}


func _synth(nm: String):
	if _snd.has(nm):
		return _snd[nm]
	var rate := 22050
	var n := 0
	var data := PackedByteArray()
	if nm == "boom":
		n = 20000
		data.resize(n * 2)
		var lp := 0.0
		for i in range(n):
			var t := float(i) / float(n)
			lp = lp * 0.96 + (randf() * 2.0 - 1.0) * 0.04
			var v := (lp * 6.0 + sin(TAU * 55.0 * float(i) / float(rate)) * 0.5) * exp(-t * 5.0)
			data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	elif nm == "swish":
		n = 3000
		data.resize(n * 2)
		var lp2 := 0.0
		for i in range(n):
			var t2 := float(i) / float(n)
			lp2 = lp2 * 0.6 + (randf() * 2.0 - 1.0) * 0.4
			data.encode_s16(i * 2, int(clampf(lp2 * sin(PI * t2) * 0.6, -1.0, 1.0) * 30000.0))
	else:
		return null
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.data = data
	_snd[nm] = s
	return s


func _sound(pos: Vector3, nm: String, vol: float) -> void:
	var st = _synth(nm)
	if st == null:
		return
	var ap := AudioStreamPlayer3D.new()
	ap.stream = st
	ap.volume_db = vol
	ap.unit_size = 18.0
	ap.max_distance = 220.0
	g.add_child(ap)
	ap.global_position = pos
	ap.finished.connect(ap.queue_free)
	ap.play()
