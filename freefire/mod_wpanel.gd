extends RefCounted
# mod_wpanel.gd (3-akkaunt). Yuqori o'ng qurol paneli.
# - qurol rasmi haqiqiy 3D modeldan (bir marta chiziladi, keyin keshlanadi); modeli yo'q qurolga siluet,
#   sovuq qurolga (musht, kastet, pichoq, qilich, balta) o'zimiz chizgan ikonka
# - 2 yoki 4 katak (player.slot_wid uzunligiga qarab), bosib tanlash
# - tugmalar bilan ustma-ust tushsa, matn tugmadan o'ngga suriladi
# Yadro fayllarga HOOK kerak emas. Ishlatadi: g.player, g.ui, g.menu_panel, g._btns(), g._btn_at(), g._gun_icon(),
# player.swap() / select_slot(i) (bo'lsa), player._make_model(), fighter.gd MODEL_FOR / MODELS, res://freefire/weapons.gd

const AMBER := Color(1.0, 0.78, 0.2, 0.95)
const BG := Color(0.03, 0.04, 0.06, 0.97)

var g
var _wl: Array = []
var _tex := {}
var _tex_s := {}
var _busy := {}
var _keys := {}
var _ov := []
var _last_tap := 0
var _pad := 8.0
var _pad_frame := -100


func setup(game) -> void:
	g = game


func on_lobby() -> void:
	_hide_ov()


func on_match_end(_win) -> void:
	_hide_ov()


func _hide_ov() -> void:
	for c in _ov:
		if is_instance_valid(c):
			c.visible = false


# ---------- qurol ro'yxati va rasmi ----------
func _wlist() -> Array:
	if not _wl.is_empty():
		return _wl
	var s = load("res://freefire/weapons.gd")
	if s != null:
		_wl = s.W
	return _wl


func _is_melee(wl: Array, wid: int) -> bool:
	var d: Dictionary = wl[wid]
	return str(d.get("cat", "")) == "melee" or str(d["s"]) == "melee"


func _key_for(wid: int, wl: Array) -> String:
	if _keys.has(wid):
		return _keys[wid]
	var f = g.player
	var nm: String = str(wl[wid]["n"])
	var cm: Dictionary = f.get_script().get_script_constant_map()
	var mf: Dictionary = cm.get("MODEL_FOR", {})
	var k: String = str(mf.get(nm, ""))
	if k == "" and f.has_method("guns_key"):
		k = str(f.guns_key(wl[wid]))
	if k == "":
		var models: Dictionary = cm.get("MODELS", {})
		for mk in models:
			if str(mk).to_upper() == nm.to_upper():
				k = str(mk)
	_keys[wid] = k
	return k


func _request(key: String) -> void:
	if _busy.has(key):
		return
	_busy[key] = true
	_render(key)


func _render(key: String) -> void:
	var f = g.player
	if f == null or not f.has_method("_make_model"):
		return
	var mdl = f._make_model(key)
	if mdl == null:
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(512, 192)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	g.add_child(vp)
	var holder: Node3D = mdl["node"]
	vp.add_child(holder)
	var box := AABB()
	var first := true
	for n in holder.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n
		var bb: AABB = mi.global_transform * mi.get_aabb()
		if first:
			box = bb
			first = false
		else:
			box = box.merge(bb)
	if first:
		vp.queue_free()
		return
	var ctr: Vector3 = box.get_center()
	var aspect: float = 512.0 / 192.0
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(box.size.y, box.size.z / aspect) * 1.12
	cam.near = 0.05
	cam.far = 30.0
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.ambient_light_energy = 0.9
	cam.environment = env
	vp.add_child(cam)
	cam.look_at_from_position(ctr + Vector3(6.0, 0.0, 0.0), ctr, Vector3.UP)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.3
	vp.add_child(sun)
	sun.rotation_degrees = Vector3(-35.0, 60.0, 0.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty():
		return
	_tex[key] = ImageTexture.create_from_image(img)
	var small: Image = img.duplicate()
	small.resize(256, 96, Image.INTERPOLATE_LANCZOS)
	_tex_s[key] = ImageTexture.create_from_image(small)


func _draw_gun(hud, wl: Array, wid: int, r: Rect2, big: bool, dim: float) -> void:
	if wid < 0:
		return
	var col := Color(1, 1, 1, 0.92 * dim)
	if _is_melee(wl, wid):
		_melee_icon(hud, str(wl[wid]["n"]), r, col)
		return
	var key: String = _key_for(wid, wl)
	if key != "":
		var t = (_tex if big else _tex_s).get(key)
		if t == null:
			_request(key)
		else:
			var ts: Vector2 = t.get_size()
			var sc: float = minf(r.size.x / ts.x, r.size.y / ts.y)
			var sz: Vector2 = ts * sc
			hud.draw_texture_rect(t, Rect2(r.position + (r.size - sz) * 0.5, sz), false, Color(1, 1, 1, dim))
			return
	g._gun_icon(str(wl[wid]["s"]), r, col, hud)


# ---------- sovuq qurol ikonkalari ----------
func _pt(r: Rect2, x: float, y: float) -> Vector2:
	return Vector2(r.position.x + x * r.size.x, r.position.y + y * r.size.y)


func _box(hud, r: Rect2, x0: float, y0: float, x1: float, y1: float, col: Color) -> void:
	hud.draw_rect(Rect2(_pt(r, x0, y0), Vector2((x1 - x0) * r.size.x, (y1 - y0) * r.size.y)), col)


func _poly(hud, r: Rect2, pts: Array, col: Color) -> void:
	var v := PackedVector2Array()
	for q in pts:
		v.append(_pt(r, float(q[0]), float(q[1])))
	hud.draw_colored_polygon(v, col)


func _melee_icon(hud, nm: String, r: Rect2, col: Color) -> void:
	var dark := Color(col.r * 0.55, col.g * 0.55, col.b * 0.55, col.a)
	match nm.to_upper():
		"PICHOQ":
			_box(hud, r, 0.06, 0.43, 0.34, 0.59, dark)
			_box(hud, r, 0.34, 0.33, 0.40, 0.67, col)
			_poly(hud, r, [[0.40, 0.40], [0.80, 0.40], [0.96, 0.55], [0.40, 0.58]], col)
		"QILICH":
			_box(hud, r, 0.03, 0.46, 0.20, 0.55, dark)
			_box(hud, r, 0.20, 0.28, 0.26, 0.72, col)
			_poly(hud, r, [[0.26, 0.44], [0.90, 0.44], [0.99, 0.50], [0.90, 0.57], [0.26, 0.57]], col)
		"BALTA":
			_box(hud, r, 0.08, 0.47, 0.82, 0.55, dark)
			_poly(hud, r, [[0.60, 0.18], [0.84, 0.26], [0.88, 0.74], [0.60, 0.82], [0.70, 0.50]], col)
		"KASTET":
			for i in range(4):
				var c := _pt(r, 0.2 + 0.2 * float(i), 0.46)
				hud.draw_arc(c, minf(r.size.x, r.size.y) * 0.13, 0.0, TAU, 14, col, maxf(2.0, r.size.y * 0.07))
			_box(hud, r, 0.10, 0.62, 0.92, 0.72, col)
		_:
			# musht
			_box(hud, r, 0.28, 0.34, 0.74, 0.80, col)
			for i in range(4):
				hud.draw_circle(_pt(r, 0.34 + 0.12 * float(i), 0.34), minf(r.size.x, r.size.y) * 0.09, col)
			hud.draw_circle(_pt(r, 0.26, 0.62), minf(r.size.x, r.size.y) * 0.10, dark)


# ---------- panel ----------
# Tugma doirasi panelga tegsa, matn boshlanishini shu doiradan o'ngga suradi (har 20 kadrda hisoblanadi).
func _free_left(r: Rect2, k: float) -> float:
	var fr: int = Engine.get_process_frames()
	if fr - _pad_frame < 20:
		return _pad
	_pad_frame = fr
	var pad: float = 8.0 * k
	for b in g._btns():
		var c: Vector2 = b[1]
		var rad: float = b[2]
		var q := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
		if q.distance_to(c) < rad and c.x < r.position.x + r.size.x * 0.5:
			pad = maxf(pad, c.x + rad + 6.0 * k - r.position.x)
	_pad = minf(pad, 90.0 * k)
	return _pad


func draw_hud(hud, vs: Vector2, k: float) -> void:
	var p = g.player
	if p == null:
		return
	var wl: Array = _wlist()
	if wl.is_empty():
		return
	var font := ThemeDB.fallback_font
	var w: float = 300.0 * k
	var o := Vector2(vs.x - w - 14.0 * k, 92.0 * k)
	var main := Rect2(o, Vector2(w, 100.0 * k))
	var n: int = clampi(p.slot_wid.size(), 2, 4)
	var gap: float = 5.0 * k
	var cwid: float = (w - gap * float(n - 1)) / float(n)
	var rects: Array = []
	for i in range(n):
		rects.append(Rect2(o + Vector2(float(i) * (cwid + gap), 106.0 * k), Vector2(cwid, 46.0 * k)))
	hud.draw_rect(Rect2(o, Vector2(w, 152.0 * k)), BG)
	var wid: int = int(p.wid)
	var wd: Dictionary = wl[wid]
	var melee: bool = _is_melee(wl, wid)
	var reloading: bool = float(p.rl) > 0.0 and not melee
	var low: bool = (not melee) and float(p.mag) <= float(wd["mag"]) * 0.25
	hud.draw_rect(main, Color(0.07, 0.09, 0.13, 1.0))
	hud.draw_rect(main, AMBER, false, 2.5)
	var pad: float = _free_left(main, k)
	var ix: float = o.x + pad
	var cw: float = w - pad - 8.0 * k
	_draw_gun(hud, wl, wid, Rect2(Vector2(ix, o.y + 6.0 * k), Vector2(cw * 0.62, 66.0 * k)), true, 1.0)
	var ax: float = ix + cw * 0.64
	if melee:
		hud.draw_string(font, Vector2(ax, o.y + 44.0 * k), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, int(40.0 * k), Color(1, 1, 1, 0.5))
	else:
		var ms: String = str(int(p.mag))
		var mcol: Color = Color(1.0, 0.3, 0.25) if (low and not reloading) else Color.WHITE
		hud.draw_string(font, Vector2(ax, o.y + 46.0 * k), ms, HORIZONTAL_ALIGNMENT_LEFT, -1, int(40.0 * k), mcol)
		hud.draw_string(font, Vector2(ax + float(ms.length()) * 22.0 * k + 2.0 * k, o.y + 46.0 * k), "/" + str(int(p.slot_res[int(p.slot)])), HORIZONTAL_ALIGNMENT_LEFT, -1, int(20.0 * k), Color(1, 1, 1, 0.65))
		var frac: float = 1.0
		if reloading:
			frac = 1.0 - clampf(float(p.rl) / float(wd["rl"]), 0.0, 1.0)
		else:
			frac = clampf(float(p.mag) / float(wd["mag"]), 0.0, 1.0)
		hud.draw_rect(Rect2(Vector2(ix, o.y + 91.0 * k), Vector2(cw, 5.0 * k)), Color(1, 1, 1, 0.18))
		hud.draw_rect(Rect2(Vector2(ix, o.y + 91.0 * k), Vector2(cw * frac, 5.0 * k)), mcol if (low and not reloading) else AMBER)
	var nm: String = "ZARYADLANMOQDA" if reloading else str(wd["n"])
	hud.draw_string(font, Vector2(ix, o.y + 86.0 * k), nm, HORIZONTAL_ALIGNMENT_LEFT, cw, int(16.0 * k), AMBER if reloading else Color(1, 1, 1, 0.92))
	for i in range(n):
		_slot(hud, font, wl, p, i, rects[i], k)
	_ensure_ov(n)
	for i in range(n):
		_place(i, rects[i])


func _slot(hud, font: Font, wl: Array, p, i: int, r: Rect2, k: float) -> void:
	var act: bool = (i == int(p.slot))
	var wid: int = int(p.slot_wid[i])
	hud.draw_rect(r, Color(0.07, 0.09, 0.13, 1.0) if act else Color(0.05, 0.06, 0.09, 1.0))
	hud.draw_rect(r, AMBER if act else Color(1, 1, 1, 0.38), false, 2.0)
	hud.draw_string(font, r.position + Vector2(5.0 * k, 14.0 * k), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, int(12.0 * k), AMBER if act else Color(1, 1, 1, 0.55))
	if wid < 0:
		return
	var narrow: bool = r.size.x < 110.0 * k
	var ir: Rect2
	if narrow:
		ir = Rect2(r.position + Vector2(8.0 * k, 4.0 * k), Vector2(r.size.x - 16.0 * k, r.size.y - 19.0 * k))
	else:
		ir = Rect2(r.position + Vector2(18.0 * k, 4.0 * k), Vector2(r.size.x * 0.56, r.size.y - 8.0 * k))
	_draw_gun(hud, wl, wid, ir, false, 1.0 if act else 0.7)
	if _is_melee(wl, wid):
		return
	var res: String = str(int(p.slot_res[i]))
	var tc := Color(1, 1, 1, 0.9 if act else 0.6)
	if narrow:
		hud.draw_string(font, Vector2(r.position.x, r.position.y + r.size.y - 4.0 * k), res, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 5.0 * k, int(13.0 * k), tc)
	else:
		hud.draw_string(font, r.position + Vector2(r.size.x * 0.66, r.size.y - 14.0 * k), res, HORIZONTAL_ALIGNMENT_LEFT, -1, int(18.0 * k), tc)


# ---------- bosib tanlash ----------
func _ensure_ov(n: int) -> void:
	if _ov.size() == n:
		var ok := true
		for c in _ov:
			if not is_instance_valid(c):
				ok = false
		if ok:
			return
	if g.ui == null:
		return
	for c in _ov:
		if is_instance_valid(c):
			c.queue_free()
	_ov.clear()
	for i in range(n):
		var c := Control.new()
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.gui_input.connect(_on_ov.bind(i))
		g.ui.add_child(c)
		_ov.append(c)


func _place(i: int, r: Rect2) -> void:
	if i >= _ov.size() or not is_instance_valid(_ov[i]):
		return
	var c: Control = _ov[i]
	c.visible = true
	c.position = r.position
	c.size = r.size


func _on_ov(e: InputEvent, i: int) -> void:
	var local := Vector2.ZERO
	if e is InputEventScreenTouch and e.pressed:
		local = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		local = e.position
	else:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_tap < 250:
		return
	var p = g.player
	if p == null or not p.alive:
		return
	if g.menu_panel != null and g.menu_panel.visible:
		return
	var c: Control = _ov[i]
	if g._btn_at(c.global_position + local) != "":
		return
	if int(p.slot) == i or int(p.slot_wid[i]) < 0:
		return
	_last_tap = now
	if p.has_method("select_slot"):
		p.select_slot(i)
	elif i < 2:
		p.swap()
