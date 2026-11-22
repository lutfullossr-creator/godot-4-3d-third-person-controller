extends Node3D

const Fighter = preload("res://freefire/fighter.gd")
const WeaponDB = preload("res://freefire/weapons.gd")
enum S { MENU, PICK, LIVE, END }

var state := S.MENU
var mode_n := 1
var round_i := 0
var score := [0, 0]
var fighters: Array = []
var player = null
var cam: Camera3D
var ui: CanvasLayer
var hud: Control
var lbl_top: Label
var lbl_w: Label
var lbl_hp: Label
var lbl_msg: Label
var menu_panel: PanelContainer
var menu_title: Label
var pick_panel: PanelContainer
var pick_title: Label
var msg_t := 0.0
var end_t := 0.0
var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO
var look_id := -1
var btn_ids := {}
var touch_fire := false
var zoomed := false
var round_t := 60.0
var dmg_t := 0.0
var hitm_t := 0.0
var hitm_head := false
var feed: Array = []
var sfx2d: AudioStreamPlayer


func _ready() -> void:
	randomize()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	sfx2d = AudioStreamPlayer.new()
	add_child(sfx2d)
	_build_world()
	_build_ui()
	_show_menu("ZONA: ULTIMATUM")


func _ld(n: String):
	for ext in [".ogg", ".wav"]:
		var p := "res://freefire/audio/%s%s" % [n, ext]
		if ResourceLoader.exists(p):
			return load(p)
	return null


# ---------- dunyo ----------
func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	m.material_override = mat
	b.add_child(m)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	b.add_child(c)
	b.position = pos
	add_child(b)


func _build_world() -> void:
	_box(Vector3(0, -0.5, 0), Vector3(44, 1, 44), Color(0.55, 0.55, 0.5))
	var wc := Color(0.4, 0.45, 0.4)
	_box(Vector3(0, 2, -22), Vector3(44, 4, 1), wc)
	_box(Vector3(0, 2, 22), Vector3(44, 4, 1), wc)
	_box(Vector3(-22, 2, 0), Vector3(1, 4, 44), wc)
	_box(Vector3(22, 2, 0), Vector3(1, 4, 44), wc)
	var crates := [
		[Vector3(-6, 0.75, 6), Vector3(3, 1.5, 3)],
		[Vector3(6, 1, 2), Vector3(2, 2, 5)],
		[Vector3(0, 0.6, -2), Vector3(5, 1.2, 1.2)],
		[Vector3(-9, 1, -6), Vector3(2.5, 2, 2.5)],
		[Vector3(9, 0.75, -9), Vector3(3, 1.5, 3)],
		[Vector3(-2, 1, -12), Vector3(5, 2, 1.2)],
		[Vector3(-14, 1, 0), Vector3(1.2, 2, 6)],
		[Vector3(14, 1, 4), Vector3(1.2, 2, 6)],
	]
	for c in crates:
		_box(c[0], c[1], Color(0.6, 0.45, 0.28))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.55, 0.65)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.6)
	we.environment = e
	add_child(we)
	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.position = Vector3(0, 6, 24)
	cam.rotation_degrees = Vector3(-15, 0, 0)


# ---------- interfeys ----------
func _lab(txt: String, sz: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _center(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	ui.add_child(hud)
	lbl_top = _lab("", 30)
	lbl_w = _lab("", 28)
	lbl_hp = _lab("", 28)
	lbl_msg = _lab("", 44)
	lbl_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for l in [lbl_top, lbl_w, lbl_hp, lbl_msg]:
		hud.add_child(l)
	# menyu
	menu_panel = PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	menu_title = _lab("", 40)
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(menu_title)
	for n in [1, 2]:
		var b := Button.new()
		b.text = "%d VA %d" % [n, n]
		b.custom_minimum_size = Vector2(320, 90)
		b.add_theme_font_size_override("font_size", 34)
		b.pressed.connect(_start_match.bind(n))
		vb.add_child(b)
	menu_panel.add_child(vb)
	ui.add_child(menu_panel)
	_center(menu_panel)
	# qurol tanlash
	pick_panel = PanelContainer.new()
	var pv := VBoxContainer.new()
	pick_title = _lab("", 32)
	pick_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pick_title)
	var gr := GridContainer.new()
	gr.columns = 4
	gr.add_theme_constant_override("h_separation", 8)
	gr.add_theme_constant_override("v_separation", 8)
	for i in range(WeaponDB.W.size()):
		var w: Dictionary = WeaponDB.W[i]
		var b := Button.new()
		b.text = "%s\n%d zarar" % [w["n"], w["dmg"]]
		b.custom_minimum_size = Vector2(180, 80)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_on_pick.bind(i))
		gr.add_child(b)
	pv.add_child(gr)
	pick_panel.add_child(pv)
	ui.add_child(pick_panel)
	_center(pick_panel)
	pick_panel.visible = false


func _show_menu(title: String) -> void:
	menu_title.text = title
	menu_panel.visible = true
	pick_panel.visible = false
	state = S.MENU


func _msg(s: String, t: float = 2.0) -> void:
	lbl_msg.text = s
	msg_t = t


# ---------- match mantiqi ----------
func _start_match(n: int) -> void:
	mode_n = n
	round_i = 0
	score = [0, 0]
	for f in fighters:
		f.queue_free()
	fighters.clear()
	player = null
	for t in [0, 1]:
		for k in range(n):
			var f = Fighter.new()
			f.setup(t, not (t == 0 and k == 0))
			add_child(f)
			f.hit_info.connect(_on_hit)
			fighters.append(f)
			if t == 0 and k == 0:
				player = f
	menu_panel.visible = false
	_begin_round()


func _give(f, i: int) -> void:
	f.give(i)


func _begin_round() -> void:
	touch_fire = false
	round_t = 60.0
	zoomed = false
	cam.fov = 75.0
	feed.clear()
	for t in [0, 1]:
		var idx := 0
		for f in fighters:
			if f.team != t:
				continue
			var x := (idx - (mode_n - 1) * 0.5) * 4.0
			f.reset(Vector3(x, 0.1, 16.0 if t == 0 else -16.0), 0.0 if t == 0 else PI)
			idx += 1
	state = S.PICK
	if round_i < 2:
		pick_title.text = "Raund %d/5: qurol tanlang (hamma shu qurol bilan)" % (round_i + 1)
		pick_panel.visible = true
	elif round_i < 4:
		var i: int = randi() % WeaponDB.W.size()
		for f in fighters:
			_give(f, i)
		_go_live("Raqib tanladi: %s" % WeaponDB.W[i]["n"])
	else:
		pick_title.text = "5-raund: oʻz qurolingizni tanlang"
		pick_panel.visible = true


func _on_pick(i: int) -> void:
	if state != S.PICK:
		return
	if round_i < 2:
		for f in fighters:
			_give(f, i)
	else:
		for f in fighters:
			_give(f, i if f == player else randi() % WeaponDB.W.size())
	pick_panel.visible = false
	_go_live("Raund %d: OT!" % (round_i + 1))


func _go_live(m: String) -> void:
	state = S.LIVE
	_msg(m, 2.0)


func _end_round(w: int) -> void:
	score[w] += 1
	state = S.END
	end_t = 3.0
	for f in fighters:
		f.move_input = Vector2.ZERO
		f.want_fire = false
	touch_fire = false
	_msg("RAUND YUTDINGIZ!" if w == 0 else "Raund yutqazildi", 3.0)


func _check_round(delta: float) -> void:
	var a := [0, 0]
	var hpsum := [0, 0]
	for f in fighters:
		if f.alive:
			a[f.team] += 1
			hpsum[f.team] += f.hp
	if a[0] == 0 or a[1] == 0:
		_end_round(1 if a[0] == 0 else 0)
		return
	round_t -= delta
	if round_t <= 0.0:
		_end_round(0 if hpsum[0] >= hpsum[1] else 1)


func _name_of(f) -> String:
	if f == player:
		return "Siz"
	if f.team == player.team:
		return "Do'st"
	return "Raqib %d" % fighters.find(f)


func _on_hit(attacker, target, dmg: int, head: bool) -> void:
	if state != S.LIVE:
		return
	if attacker == player:
		sfx2d.stream = _ld("headshot" if head else "hit")
		sfx2d.volume_db = -3.0
		if sfx2d.stream != null:
			sfx2d.play()
		hitm_t = 0.2
		hitm_head = head
		_msg(("HEADSHOT! " if head else "") + str(dmg), 0.8)
	if target == player:
		dmg_t = 0.4
	if target.hp <= 0:
		feed.append({"t": 4.0, "s": "%s  >  %s%s" % [_name_of(attacker), _name_of(target), "  [HEADSHOT]" if head else ""]})
		if feed.size() > 4:
			feed.pop_front()


# ---------- botlar ----------
func _nearest_enemy(b):
	var best = null
	var bd := 1e9
	for f in fighters:
		if f.team != b.team and f.alive:
			var d: float = b.global_position.distance_to(f.global_position)
			if d < bd:
				bd = d
				best = f
	return best


func _think(b, delta: float) -> void:
	var t = _nearest_enemy(b)
	if t == null:
		b.move_input = Vector2.ZERO
		b.want_fire = false
		return
	var to: Vector3 = t.global_position - b.global_position
	var flat := Vector3(to.x, 0.0, to.z)
	var dist := flat.length()
	b.yaw = lerp_angle(b.yaw, atan2(-to.x, -to.z), clampf(3.0 * delta, 0.0, 1.0))
	var facing := Vector3(-sin(b.yaw), 0.0, -cos(b.yaw))
	b.ai_t -= delta
	if b.ai_t <= 0.0:
		b.ai_t = randf_range(0.8, 2.0)
		b.ai_strafe = [-1.0, 0.0, 1.0][randi() % 3]
		b.ai_head = randf() < 0.25
		b.stance = 1 if randf() > 0.8 else 0
		if randf() < 0.1:
			b.want_jump = true
	var fw := -1.0 if dist > 12.0 else (1.0 if dist < 5.0 else 0.0)
	b.move_input = Vector2(b.ai_strafe * 0.7, fw)
	var aim_pt: Vector3 = t.aim_point(b.ai_head)
	b.use_origin = false
	b.aim_dir = (aim_pt - b.eye()).normalized()
	b.want_fire = dist < 45.0 and facing.dot(flat.normalized()) > 0.9


# ---------- oyinchi ----------
func _player_input(delta: float) -> void:
	var p = player
	if p == null or not p.alive:
		return
	var mv := stick_vec
	if Input.is_key_pressed(KEY_W):
		mv.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		mv.y += 1.0
	if Input.is_key_pressed(KEY_A):
		mv.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		mv.x += 1.0
	p.move_input = mv.limit_length(1.0)
	if Input.is_key_pressed(KEY_LEFT):
		p.yaw += 2.0 * delta
	if Input.is_key_pressed(KEY_RIGHT):
		p.yaw -= 2.0 * delta
	if Input.is_key_pressed(KEY_UP):
		p.pitch = clampf(p.pitch + 1.2 * delta, -1.0, 1.0)
	if Input.is_key_pressed(KEY_DOWN):
		p.pitch = clampf(p.pitch - 1.2 * delta, -1.0, 1.0)
	if Input.is_key_pressed(KEY_SPACE):
		p.want_jump = true
	p.want_fire = touch_fire or Input.is_key_pressed(KEY_F)
	if p.want_fire:
		_assist(p, delta)


func _assist(p, delta: float) -> void:
	var best = null
	var bd := 0.14
	var fwd := Basis.from_euler(Vector3(p.pitch, p.yaw, 0.0)) * Vector3(0, 0, -1)
	var eye_p: Vector3 = p.eye()
	for f in fighters:
		if f.team != p.team and f.alive:
			var dir: Vector3 = (f.aim_point(false) - eye_p).normalized()
			var ang := fwd.angle_to(dir)
			if ang < bd:
				bd = ang
				best = f
	if best == null:
		return
	var dv: Vector3 = (best.aim_point(false) - eye_p).normalized()
	var ty := atan2(-dv.x, -dv.z)
	var tp := asin(clampf(dv.y, -1.0, 1.0))
	p.yaw = lerp_angle(p.yaw, ty, clampf(4.0 * delta, 0.0, 1.0))
	p.pitch = lerpf(p.pitch, tp, clampf(4.0 * delta, 0.0, 1.0))


func _spectate_target():
	for f in fighters:
		if f.alive and f.team == player.team:
			return f
	for f in fighters:
		if f.alive:
			return f
	return player


func _update_cam() -> void:
	var p = player
	if p == null:
		return
	var v = p
	if not p.alive:
		v = _spectate_target()
	var d := Basis.from_euler(Vector3(v.pitch, v.yaw, 0.0)) * Vector3(0, 0, -1)
	var right := Vector3(cos(v.yaw), 0.0, -sin(v.yaw))
	var pos: Vector3 = v.eye() - d * 3.0 + right * 0.6 + Vector3.UP * 0.3
	pos += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * v.kick * 0.012
	pos.y = maxf(pos.y, 0.3)
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(v.pitch, v.yaw, 0.0)), pos)
	if p.alive:
		p.aim_dir = d
		p.origin_override = pos
		p.use_origin = true


func _toggle_stance(s: int) -> void:
	if player != null and player.alive:
		player.stance = 0 if player.stance == s else s


func _btns() -> Array:
	var vs := get_viewport().get_visible_rect().size
	return [
		["fire", Vector2(vs.x - 130, vs.y - 140), 65.0, "OT"],
		["jump", Vector2(vs.x - 260, vs.y - 80), 40.0, "SAK"],
		["crouch", Vector2(vs.x - 250, vs.y - 190), 36.0, "CHO"],
		["prone", Vector2(vs.x - 340, vs.y - 130), 36.0, "YOT"],
		["reload", Vector2(vs.x - 80, vs.y - 280), 36.0, "ZAR"],
		["swap", Vector2(vs.x - 340, vs.y - 230), 34.0, "QUR"],
		["zoom", Vector2(vs.x - 190, vs.y - 270), 34.0, "NIS"],
		["pause", Vector2(vs.x - 50, 50), 28.0, "II"],
	]


func _btn_at(p: Vector2) -> String:
	for b in _btns():
		if p.distance_to(b[1]) <= b[2] + 12.0:
			return b[0]
	return ""


func _btn_down(n: String) -> void:
	if n == "pause":
		_show_menu("PAUZA")
		return
	if player == null or not player.alive:
		return
	match n:
		"fire":
			touch_fire = true
		"jump":
			player.want_jump = true
		"crouch":
			_toggle_stance(1)
		"prone":
			_toggle_stance(2)
		"reload":
			player.reload()
		"swap":
			player.swap()
		"zoom":
			zoomed = not zoomed


func _input(e: InputEvent) -> void:
	if state != S.LIVE and state != S.END:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_C:
				_toggle_stance(1)
			KEY_Z:
				_toggle_stance(2)
			KEY_R:
				if player != null:
					player.reload()
			KEY_Q:
				if player != null:
					player.swap()
			KEY_V:
				zoomed = not zoomed
		return
	var vs := get_viewport().get_visible_rect().size
	if e is InputEventScreenTouch:
		if e.pressed:
			var b := _btn_at(e.position)
			if b != "":
				btn_ids[e.index] = b
				_btn_down(b)
			elif e.position.x < vs.x * 0.4 and stick_id == -1:
				stick_id = e.index
				stick_origin = e.position
				stick_vec = Vector2.ZERO
			elif look_id == -1:
				look_id = e.index
		else:
			if btn_ids.has(e.index):
				if btn_ids[e.index] == "fire":
					touch_fire = false
				btn_ids.erase(e.index)
			if e.index == stick_id:
				stick_id = -1
				stick_vec = Vector2.ZERO
			if e.index == look_id:
				look_id = -1
	elif e is InputEventScreenDrag:
		if e.index == stick_id:
			stick_vec = ((e.position - stick_origin) / 70.0).limit_length(1.0)
		elif e.index == look_id and player != null:
			var sens := 0.45 if zoomed else 1.0
			player.yaw -= e.relative.x * 0.005 * sens
			player.pitch = clampf(player.pitch - e.relative.y * 0.004 * sens, -1.0, 1.0)


# ---------- har kadr ----------
func _process(delta: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	lbl_top.custom_minimum_size = Vector2(700, 0)
	lbl_top.position = Vector2(vs.x * 0.5 - 350, 8)
	lbl_msg.custom_minimum_size = Vector2(vs.x, 0)
	lbl_msg.position = Vector2(0, vs.y * 0.22)
	lbl_w.position = Vector2(20, vs.y - 60)
	lbl_hp.position = Vector2(20, vs.y - 110)
	if state == S.LIVE:
		_player_input(delta)
		for f in fighters:
			if f.is_bot and f.alive:
				_think(f, delta)
		_check_round(delta)
		if player != null and not player.alive:
			_msg("Siz oldingiz, kuzatilmoqda...", 0.3)
	elif state == S.END:
		end_t -= delta
		if end_t <= 0.0:
			if score[0] >= 3 or score[1] >= 3:
				_show_menu("GʻALABA!" if score[0] >= 3 else "Magʻlubiyat")
				lbl_msg.text = ""
			else:
				round_i += 1
				_begin_round()
	if player != null and state != S.MENU:
		_update_cam()
		lbl_top.text = "Raund %d/5     %d : %d     %d s" % [mini(round_i + 1, 5), score[0], score[1], int(ceil(maxf(round_t, 0.0)))]
		var w: Dictionary = WeaponDB.W[player.wid]
		var alt: String = WeaponDB.W[player.slot_wid[1 - player.slot]]["n"]
		lbl_w.text = "%s  %s    [%s]" % [w["n"], "ZARYAD..." if player.rl > 0.0 else "%d/%d" % [player.mag, w["mag"]], alt]
		lbl_hp.text = "HP %d/200" % player.hp
	else:
		lbl_top.text = ""
		lbl_w.text = ""
		lbl_hp.text = ""
	dmg_t = maxf(dmg_t - delta, 0.0)
	hitm_t = maxf(hitm_t - delta, 0.0)
	for it in feed:
		it["t"] = float(it["t"]) - delta
	feed = feed.filter(func(it): return float(it["t"]) > 0.0)
	cam.fov = lerpf(cam.fov, 35.0 if zoomed else 75.0, clampf(10.0 * delta, 0.0, 1.0))
	msg_t -= delta
	if msg_t <= 0.0 and state != S.END:
		lbl_msg.text = ""
	hud.queue_redraw()


func _draw_hud() -> void:
	if state == S.MENU or player == null:
		return
	var vs := get_viewport().get_visible_rect().size
	var c := vs * 0.5
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		hud.draw_line(c + d * 4.0, c + d * 14.0, Color.WHITE, 2.0)
	if state == S.PICK:
		return
	if dmg_t > 0.0:
		hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0, 0, dmg_t * 0.7))
	if player.alive and player.hp < 60:
		hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.6, 0, 0, 0.12))
	if hitm_t > 0.0:
		var hc := Color(1, 0.2, 0.2) if hitm_head else Color.WHITE
		for d2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			hud.draw_line(c + d2 * 8.0, c + d2 * 18.0, hc, 3.0)
	for i in range(feed.size()):
		hud.draw_string(ThemeDB.fallback_font, Vector2(vs.x - 560, 110 + i * 30), str(feed[i]["s"]), HORIZONTAL_ALIGNMENT_RIGHT, 520.0, 22)
	if stick_id != -1:
		hud.draw_circle(stick_origin, 70.0, Color(1, 1, 1, 0.15))
		hud.draw_circle(stick_origin + stick_vec * 70.0, 30.0, Color(1, 1, 1, 0.4))
	var down: Array = btn_ids.values()
	for b in _btns():
		var a := 0.7 if down.has(b[0]) else 0.35
		hud.draw_circle(b[1], b[2], Color(1.0, 0.55, 0.1, a))
		hud.draw_string(ThemeDB.fallback_font, b[1] + Vector2(-b[2], 10), b[3], HORIZONTAL_ALIGNMENT_CENTER, b[2] * 2.0, 26)
