extends "res://freefire/ultimatum.gd"

const DEAD := 0.12
const LOOK_X := 0.0035
const LOOK_Y := 0.0028
const ACCENT := Color(1.0, 0.62, 0.1)
const STANCE_K := [1.0, 0.7, 0.5]

var _thumb := Vector2.ZERO
var _xh := 10.0
var _hit_t := 0.0
var _hit_head := false
var _hit_kill := false
var _hurt_t := 0.0
var _dnums: Array = []


func _u() -> float:
	return get_viewport().get_visible_rect().size.y / 720.0


func _stick_r() -> float:
	return 108.0 * _u()


func _stick_home() -> Vector2:
	return Vector2(285.0, 500.0) * _u()


func _in_stick_zone(p: Vector2) -> bool:
	var vs := get_viewport().get_visible_rect().size
	return p.x < vs.x * 0.42 and p.y > vs.y * 0.2


func _btns() -> Array:
	var vs := get_viewport().get_visible_rect().size
	var u := vs.y / 720.0
	var w := vs.x
	return [
		["fire", Vector2(w - 372.0 * u, vs.y - 262.0 * u), 72.0 * u, ""],
		["jump", Vector2(w - 165.0 * u, vs.y - 232.0 * u), 72.0 * u, ""],
		["crouch", Vector2(w - 200.0 * u, vs.y - 62.0 * u), 50.0 * u, ""],
		["prone", Vector2(w - 372.0 * u, vs.y - 60.0 * u), 42.0 * u, ""],
		["reload", Vector2(w - 300.0 * u, vs.y - 405.0 * u), 40.0 * u, ""],
	]


func _btn_at(p: Vector2) -> String:
	for b in _btns():
		if p.distance_to(b[1]) <= b[2] * 1.15:
			return b[0]
	return ""


func _update_stick(pos: Vector2) -> void:
	var v := (pos - stick_origin) / _stick_r()
	_thumb = v.limit_length(1.0)
	var m := v.length()
	if m < DEAD:
		stick_vec = Vector2.ZERO
	else:
		stick_vec = v / m * ((minf(m, 1.0) - DEAD) / (1.0 - DEAD))


func _look(rel: Vector2) -> void:
	if player == null or not player.alive:
		return
	player.yaw -= rel.x * LOOK_X
	player.pitch = clampf(player.pitch - rel.y * LOOK_Y, -1.0, 1.0)


func _on_hit(attacker, target, dmg: int, head: bool) -> void:
	if state != S.LIVE:
		return
	if attacker == player:
		_hit_t = 0.28
		_hit_head = head
		_hit_kill = target.hp <= 0
		_dnums.append({"p": target.eye() + Vector3(0.0, 0.3, 0.0), "t": str(dmg), "a": 0.0, "h": head})
		if _hit_kill:
			_msg("KILL!", 0.7)
	if target == player:
		_hurt_t = 0.45


func _input(e: InputEvent) -> void:
	if state != S.LIVE and state != S.END:
		return
	if e is InputEventKey:
		var k := e as InputEventKey
		if k.pressed and not k.echo:
			match k.keycode:
				KEY_C:
					_toggle_stance(1)
				KEY_Z:
					_toggle_stance(2)
				KEY_R:
					if player != null:
						player.reload()
		return
	if e is InputEventScreenTouch:
		var t := e as InputEventScreenTouch
		if t.pressed:
			var b := _btn_at(t.position)
			if b != "":
				btn_ids[t.index] = b
				_btn_down(b)
			elif stick_id == -1 and _in_stick_zone(t.position):
				stick_id = t.index
				var home := _stick_home()
				if t.position.distance_to(home) <= _stick_r() * 1.6:
					stick_origin = home
				else:
					stick_origin = t.position
				_update_stick(t.position)
			elif look_id == -1:
				look_id = t.index
		else:
			if btn_ids.has(t.index):
				if btn_ids[t.index] == "fire":
					touch_fire = false
				btn_ids.erase(t.index)
			if t.index == stick_id:
				stick_id = -1
				stick_vec = Vector2.ZERO
				_thumb = Vector2.ZERO
			if t.index == look_id:
				look_id = -1
	elif e is InputEventScreenDrag:
		var d := e as InputEventScreenDrag
		if d.index == stick_id:
			_update_stick(d.position)
		elif d.index == look_id or btn_ids.get(d.index, "") == "fire":
			_look(d.relative)


func _process(delta: float) -> void:
	super(delta)
	var vs := get_viewport().get_visible_rect().size
	lbl_w.position = Vector2(vs.x * 0.5 - 150.0, vs.y - 128.0)
	lbl_hp.position = Vector2(vs.x * 0.5 - 150.0, vs.y - 88.0)
	_hit_t = maxf(0.0, _hit_t - delta)
	_hurt_t = maxf(0.0, _hurt_t - delta)
	for n in _dnums:
		n["a"] += delta
	_dnums = _dnums.filter(func(n): return n["a"] < 0.8)
	if player != null:
		var w: Dictionary = WeaponDB.W[player.wid]
		var k: float = (float(w["spread"]) + player.bloom) * (1.0 + player.move_input.length() * 0.8) * STANCE_K[player.stance]
		var want := clampf(8.0 + k * 900.0, 8.0, 80.0)
		_xh = lerpf(_xh, want, 1.0 - exp(-delta * 14.0))
	if state == S.PICK or state == S.MENU:
		stick_id = -1
		look_id = -1
		stick_vec = Vector2.ZERO
		_thumb = Vector2.ZERO
		btn_ids.clear()
		touch_fire = false
		_dnums.clear()


func _draw_hud() -> void:
	if state == S.MENU or player == null:
		return
	var vs := get_viewport().get_visible_rect().size
	var u := vs.y / 720.0
	var c := vs * 0.5
	var dirs := [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	for d in dirs:
		hud.draw_line(c + d * (_xh + 1.0), c + d * (_xh + 15.0), Color(0, 0, 0, 0.5), 5.0)
		hud.draw_line(c + d * _xh, c + d * (_xh + 14.0), Color.WHITE, 3.0)
	hud.draw_circle(c, 2.5, Color(1, 1, 1, 0.9))
	if state == S.PICK:
		return
	if _hit_t > 0.0:
		var hc := Color(1, 1, 1, _hit_t / 0.28)
		if _hit_head or _hit_kill:
			hc = Color(1.0, 0.2, 0.15, _hit_t / 0.28)
		var r0 := 12.0 + (1.0 - _hit_t / 0.28) * 8.0
		for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			hud.draw_line(c + d * r0, c + d * (r0 + 14.0), hc, 4.0)
	var font := ThemeDB.fallback_font
	for n in _dnums:
		var wp: Vector3 = n["p"] + Vector3(0.0, n["a"] * 1.3, 0.0)
		if cam.is_position_behind(wp):
			continue
		var sp := cam.unproject_position(wp)
		var al: float = 1.0 - float(n["a"]) / 0.8
		var col := Color(1.0, 0.25, 0.2, al) if n["h"] else Color(1, 1, 1, al)
		var fs := 44 if n["h"] else 32
		hud.draw_string(font, sp + Vector2(-98.0, 2.0), n["t"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, fs, Color(0, 0, 0, al))
		hud.draw_string(font, sp + Vector2(-100.0, 0.0), n["t"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, fs, col)
	if _hurt_t > 0.0:
		var ha := 0.35 * _hurt_t / 0.45
		var bw := 60.0
		var rc := Color(0.9, 0.05, 0.05, ha)
		hud.draw_rect(Rect2(0, 0, vs.x, bw), rc)
		hud.draw_rect(Rect2(0, vs.y - bw, vs.x, bw), rc)
		hud.draw_rect(Rect2(0, 0, bw, vs.y), rc)
		hud.draw_rect(Rect2(vs.x - bw, 0, bw, vs.y), rc)
	var hp := clampf(float(player.hp) / 200.0, 0.0, 1.0)
	var bx := vs.x * 0.5 - 150.0
	var by := vs.y - 44.0
	hud.draw_rect(Rect2(bx, by, 300.0, 16.0), Color(0, 0, 0, 0.45))
	var hcol := Color(0.3, 0.9, 0.35) if hp > 0.35 else Color(0.95, 0.25, 0.2)
	hud.draw_rect(Rect2(bx, by, 300.0 * hp, 16.0), hcol)
	_draw_stick(u)
	var down: Array = btn_ids.values()
	for b in _btns():
		_draw_btn(b, down.has(b[0]), u)


func _draw_stick(u: float) -> void:
	var r := _stick_r()
	var held := stick_id != -1
	var c := _stick_home()
	if held:
		c = stick_origin
	var a := 0.6 if held else 0.35
	hud.draw_circle(c, r, Color(0, 0, 0, 0.25))
	hud.draw_arc(c, r, 0.0, TAU, 64, Color(1, 1, 1, a), 3.0 * u, true)
	for i in 4:
		var d := Vector2.RIGHT.rotated(i * PI * 0.5)
		var n := d.orthogonal()
		var tip := c + d * r * 0.93
		var base := c + d * r * 0.76
		hud.draw_colored_polygon(PackedVector2Array([tip, base + n * 11.0 * u, base - n * 11.0 * u]), Color(1, 1, 1, a))
	var tr := r * 0.36
	var th := c + _thumb * (r - tr)
	hud.draw_circle(th, tr, Color(1, 1, 1, 0.5 if held else 0.28))
	hud.draw_arc(th, tr, 0.0, TAU, 32, Color(1, 1, 1, a + 0.2), 2.0 * u, true)


func _draw_btn(b: Array, pressed: bool, u: float) -> void:
	var p: Vector2 = b[1]
	var r: float = b[2] * (0.92 if pressed else 1.0)
	var on := false
	if player != null:
		on = (b[0] == "crouch" and player.stance == 1) or (b[0] == "prone" and player.stance == 2)
	var ring := Color(1, 1, 1, 0.6 if pressed else 0.38)
	if on:
		ring = ACCENT
	hud.draw_circle(p, r, Color(0, 0, 0, 0.5 if pressed else 0.3))
	hud.draw_arc(p, r, 0.0, TAU, 48, ring, 3.0 * u, true)
	var w := Color(1, 1, 1, 0.92)
	var s := r * 0.42
	var t := 5.0 * u
	match b[0]:
		"fire":
			hud.draw_arc(p, s * 0.85, 0.0, TAU, 32, w, t, true)
			hud.draw_circle(p, s * 0.25, w)
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				hud.draw_line(p + d * s * 0.95, p + d * s * 1.45, w, t)
		"jump":
			hud.draw_line(p + Vector2(0, s), p + Vector2(0, -s), w, t)
			hud.draw_line(p + Vector2(-s * 0.85, -s * 0.1), p + Vector2(0, -s), w, t)
			hud.draw_line(p + Vector2(s * 0.85, -s * 0.1), p + Vector2(0, -s), w, t)
		"crouch":
			hud.draw_line(p + Vector2(-s, -s * 0.5), p + Vector2(0, s * 0.3), w, t)
			hud.draw_line(p + Vector2(s, -s * 0.5), p + Vector2(0, s * 0.3), w, t)
			hud.draw_line(p + Vector2(-s, s * 0.85), p + Vector2(s, s * 0.85), w, t)
		"prone":
			hud.draw_line(p + Vector2(-s * 1.1, s * 0.4), p + Vector2(s * 1.1, s * 0.4), w, t)
			hud.draw_circle(p + Vector2(-s * 0.85, -s * 0.2), s * 0.3, w)
		"reload":
			hud.draw_arc(p, s, 0.8, 5.6, 32, w, t, true)
			var e := p + Vector2.RIGHT.rotated(5.6) * s
			var tg := Vector2(-sin(5.6), cos(5.6))
			var nr := Vector2(cos(5.6), sin(5.6))
			hud.draw_colored_polygon(PackedVector2Array([e + tg * s * 0.6, e + nr * s * 0.4, e - nr * s * 0.4]), w)
