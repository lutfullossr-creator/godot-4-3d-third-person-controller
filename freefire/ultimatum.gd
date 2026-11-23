extends Node3D

const Fighter = preload("res://freefire/fighter.gd")
const WeaponDB = preload("res://freefire/weapons.gd")
enum S { MENU, PICK, LIVE, END, EDIT }
const SETTINGS_PATH := "user://zona_settings.json"
const DEF_LAYOUT := {
	"fire": {"x": 0.89, "y": 0.70, "r": 82.0},
	"fire2": {"x": 0.30, "y": 0.80, "r": 64.0},
	"jump": {"x": 0.76, "y": 0.87, "r": 54.0},
	"crouch": {"x": 0.755, "y": 0.62, "r": 48.0},
	"prone": {"x": 0.65, "y": 0.80, "r": 46.0},
	"reload": {"x": 0.93, "y": 0.40, "r": 46.0},
	"swap": {"x": 0.83, "y": 0.42, "r": 46.0},
	"zoom": {"x": 0.70, "y": 0.45, "r": 46.0},
	"sprint": {"x": 0.20, "y": 0.42, "r": 46.0},
	"pause": {"x": 0.965, "y": 0.07, "r": 34.0},
}

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
var layout := {}
var cfg := {"sens": 1.0, "vol": 1.0, "assist": 1.0, "autofire": true}
var settings_panel: PanelContainer
var edit_panel: PanelContainer
var edit_lbl: Label
var resume_btn: Button
var edit_sel := ""
var edit_drag := -1


func _ready() -> void:
	randomize()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	sfx2d = AudioStreamPlayer.new()
	add_child(sfx2d)
	_load_settings()
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
	resume_btn = Button.new()
	resume_btn.text = "DAVOM ETISH"
	resume_btn.custom_minimum_size = Vector2(320, 90)
	resume_btn.add_theme_font_size_override("font_size", 34)
	resume_btn.pressed.connect(_resume)
	vb.add_child(resume_btn)
	var sb := Button.new()
	sb.text = "SOZLAMALAR"
	sb.custom_minimum_size = Vector2(320, 90)
	sb.add_theme_font_size_override("font_size", 34)
	sb.pressed.connect(_open_settings)
	vb.add_child(sb)
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
	_build_extra_ui()


func _show_menu(title: String) -> void:
	menu_title.text = title
	menu_panel.visible = true
	pick_panel.visible = false
	settings_panel.visible = false
	edit_panel.visible = false
	resume_btn.visible = (title == "PAUZA")
	state = S.MENU


func _resume() -> void:
	menu_panel.visible = false
	touch_fire = false
	btn_ids.clear()
	state = S.LIVE


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
	btn_ids.clear()
	stick_id = -1
	look_id = -1
	stick_vec = Vector2.ZERO
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
	if p.move_input.length() < 0.1:
		p.sprint = false
	var fire_on := touch_fire or Input.is_key_pressed(KEY_F)
	p.want_fire = fire_on
	if fire_on:
		_assist(p, delta)
	elif bool(cfg["autofire"]) and _best_target(p, 0.05, true) != null:
		p.want_fire = true


func _best_target(p, cone: float, los: bool):
	var best = null
	var bd := cone
	var fwd := Basis.from_euler(Vector3(p.pitch, p.yaw, 0.0)) * Vector3(0, 0, -1)
	var eye_p: Vector3 = p.eye()
	for f in fighters:
		if f.team == p.team or not f.alive:
			continue
		var tp: Vector3 = f.aim_point(false)
		var dir: Vector3 = (tp - eye_p).normalized()
		var ang := fwd.angle_to(dir)
		if ang >= bd:
			continue
		if los:
			var q := PhysicsRayQueryParameters3D.create(eye_p, tp, 1)
			var r := get_world_3d().direct_space_state.intersect_ray(q)
			if not r.is_empty():
				continue
		bd = ang
		best = f
	return best


func _assist(p, delta: float) -> void:
	var a := float(cfg["assist"])
	if a < 0.05:
		return
	var best = _best_target(p, 0.22 * a, true)
	if best == null:
		return
	var dv: Vector3 = (best.aim_point(false) - p.eye()).normalized()
	var ty := atan2(-dv.x, -dv.z)
	var tp := asin(clampf(dv.y, -1.0, 1.0))
	var k := clampf(6.0 * a * delta, 0.0, 1.0)
	p.yaw = lerp_angle(p.yaw, ty, k)
	p.pitch = lerpf(p.pitch, tp, k)


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


# ---------- sozlamalar va tugma joylashuvi ----------
func _load_settings() -> void:
	layout = {}
	for k in DEF_LAYOUT:
		var d: Dictionary = DEF_LAYOUT[k]
		layout[k] = {"x": d["x"], "y": d["y"], "s": 1.0, "a": 0.55}
	if FileAccess.file_exists(SETTINGS_PATH):
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if f != null:
			var v = JSON.parse_string(f.get_as_text())
			if v is Dictionary:
				for k in ["sens", "vol", "assist", "autofire"]:
					if v.has(k):
						cfg[k] = v[k]
				var lay = v.get("layout", {})
				if lay is Dictionary:
					for k in layout:
						if lay.has(k) and lay[k] is Dictionary:
							for kk in ["x", "y", "s", "a"]:
								if lay[k].has(kk):
									layout[k][kk] = float(lay[k][kk])
	_apply_volume()


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"sens": cfg["sens"], "vol": cfg["vol"], "assist": cfg["assist"], "autofire": cfg["autofire"], "layout": layout}))


func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(cfg["vol"]), 0.001)))


func _set_cfg(key: String, v) -> void:
	cfg[key] = v
	if key == "vol":
		_apply_volume()


func _slider_row(parent: Control, title: String, mn: float, mx: float, stp: float, key: String) -> void:
	parent.add_child(_lab(title, 26))
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = stp
	s.value = float(cfg[key])
	s.custom_minimum_size = Vector2(560, 52)
	s.value_changed.connect(func(v: float): _set_cfg(key, v))
	parent.add_child(s)


func _mini_btn(txt: String, cb: Callable, w: float = 150.0) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(w, 70)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(cb)
	return b


func _build_extra_ui() -> void:
	settings_panel = PanelContainer.new()
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 12)
	var st := _lab("SOZLAMALAR", 36)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(st)
	_slider_row(sv, "Burilish tezligi", 0.3, 2.5, 0.05, "sens")
	_slider_row(sv, "Umumiy ovoz", 0.0, 1.0, 0.05, "vol")
	_slider_row(sv, "Nishonga yordam", 0.0, 2.0, 0.1, "assist")
	var cb := CheckButton.new()
	cb.text = "Avto-otish (nishon dushmanda boʻlsa)"
	cb.button_pressed = bool(cfg["autofire"])
	cb.add_theme_font_size_override("font_size", 26)
	cb.toggled.connect(func(on: bool): _set_cfg("autofire", on))
	sv.add_child(cb)
	sv.add_child(_mini_btn("TUGMALARNI JOYLASHTIRISH", _edit_start, 560.0))
	sv.add_child(_mini_btn("SAQLASH VA ORQAGA", _close_settings, 560.0))
	settings_panel.add_child(sv)
	ui.add_child(settings_panel)
	_center(settings_panel)
	settings_panel.visible = false
	edit_panel = PanelContainer.new()
	var ev := VBoxContainer.new()
	edit_lbl = _lab("", 24)
	ev.add_child(edit_lbl)
	var er := HBoxContainer.new()
	er.add_theme_constant_override("separation", 8)
	er.add_child(_mini_btn("Kichik", _edit_scale.bind(-0.1)))
	er.add_child(_mini_btn("Katta", _edit_scale.bind(0.1)))
	er.add_child(_mini_btn("Xira", _edit_alpha.bind(-0.1)))
	er.add_child(_mini_btn("Quyuq", _edit_alpha.bind(0.1)))
	er.add_child(_mini_btn("Tiklash", _edit_reset))
	er.add_child(_mini_btn("Saqlash", _edit_done))
	ev.add_child(er)
	edit_panel.add_child(ev)
	ui.add_child(edit_panel)
	edit_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	edit_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	edit_panel.visible = false


func _open_settings() -> void:
	menu_panel.visible = false
	settings_panel.visible = true


func _close_settings() -> void:
	_save_settings()
	settings_panel.visible = false
	_show_menu(menu_title.text)


func _edit_start() -> void:
	settings_panel.visible = false
	edit_panel.visible = true
	edit_sel = "fire"
	edit_drag = -1
	state = S.EDIT
	_update_edit_label()


func _edit_done() -> void:
	_save_settings()
	edit_panel.visible = false
	settings_panel.visible = true
	state = S.MENU


func _edit_reset() -> void:
	for k in DEF_LAYOUT:
		var d: Dictionary = DEF_LAYOUT[k]
		layout[k] = {"x": d["x"], "y": d["y"], "s": 1.0, "a": 0.55}
	_update_edit_label()


func _edit_scale(d: float) -> void:
	if edit_sel != "":
		layout[edit_sel]["s"] = clampf(float(layout[edit_sel]["s"]) + d, 0.5, 2.4)
		_update_edit_label()


func _edit_alpha(d: float) -> void:
	if edit_sel != "":
		layout[edit_sel]["a"] = clampf(float(layout[edit_sel]["a"]) + d, 0.15, 1.0)
		_update_edit_label()


func _update_edit_label() -> void:
	if edit_sel == "":
		edit_lbl.text = "Tugmani ushlab suring"
	else:
		edit_lbl.text = "Tugmani ushlab suring.   Tanlangan: %s   kattaligi %d%%   zichligi %d%%" % [edit_sel.to_upper(), int(float(layout[edit_sel]["s"]) * 100.0), int(float(layout[edit_sel]["a"]) * 100.0)]


func _edit_input(e: InputEvent) -> void:
	var vs := get_viewport().get_visible_rect().size
	if e is InputEventScreenTouch:
		if e.pressed:
			var b := _btn_at(e.position)
			if b != "":
				edit_sel = b
				edit_drag = e.index
				_update_edit_label()
		elif e.index == edit_drag:
			edit_drag = -1
	elif e is InputEventScreenDrag and e.index == edit_drag and edit_sel != "":
		layout[edit_sel]["x"] = clampf(e.position.x / vs.x, 0.03, 0.97)
		layout[edit_sel]["y"] = clampf(e.position.y / vs.y, 0.05, 0.95)


func _icon(n: String, c: Vector2, r: float, col: Color) -> void:
	var u := r * 0.5
	var w := maxf(3.0, r * 0.09)
	match n:
		"fire":
			hud.draw_arc(c, u * 1.1, 0.0, TAU, 24, col, w)
			hud.draw_circle(c, u * 0.28, col)
			for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				hud.draw_line(c + d * u * 1.45, c + d * u * 0.8, col, w)
		"jump":
			hud.draw_line(c + Vector2(-u, u * 0.3), c + Vector2(0, -u * 0.6), col, w)
			hud.draw_line(c + Vector2(u, u * 0.3), c + Vector2(0, -u * 0.6), col, w)
			hud.draw_line(c + Vector2(-u, u * 0.95), c + Vector2(0, 0.05 * u), col, w)
			hud.draw_line(c + Vector2(u, u * 0.95), c + Vector2(0, 0.05 * u), col, w)
		"crouch":
			hud.draw_circle(c + Vector2(-u * 0.1, -u * 0.85), u * 0.28, col)
			hud.draw_line(c + Vector2(-u * 0.1, -u * 0.5), c + Vector2(-u * 0.1, u * 0.1), col, w)
			hud.draw_line(c + Vector2(-u * 0.1, u * 0.1), c + Vector2(u * 0.6, u * 0.1), col, w)
			hud.draw_line(c + Vector2(u * 0.6, u * 0.1), c + Vector2(u * 0.6, u * 0.85), col, w)
			hud.draw_line(c + Vector2(-u * 0.1, -u * 0.35), c + Vector2(u * 0.5, -u * 0.1), col, w)
		"prone":
			hud.draw_circle(c + Vector2(-u * 0.95, u * 0.1), u * 0.26, col)
			hud.draw_line(c + Vector2(-u * 0.6, u * 0.15), c + Vector2(u * 0.9, u * 0.15), col, w)
			hud.draw_line(c + Vector2(u * 0.9, u * 0.15), c + Vector2(u * 1.15, u * 0.5), col, w)
			hud.draw_line(c + Vector2(-u * 0.3, u * 0.15), c + Vector2(-u * 0.1, -u * 0.3), col, w)
		"reload":
			hud.draw_arc(c, u, 0.6, TAU - 0.4, 24, col, w)
			var tip := c + Vector2(cos(0.6), sin(0.6)) * u
			hud.draw_line(tip, tip + Vector2(u * 0.5, -u * 0.05), col, w)
			hud.draw_line(tip, tip + Vector2(u * 0.05, -u * 0.55), col, w)
		"swap":
			hud.draw_line(c + Vector2(-u, -u * 0.35), c + Vector2(u, -u * 0.35), col, w)
			hud.draw_line(c + Vector2(u, -u * 0.35), c + Vector2(u * 0.5, -u * 0.75), col, w)
			hud.draw_line(c + Vector2(u, -u * 0.35), c + Vector2(u * 0.5, u * 0.05), col, w)
			hud.draw_line(c + Vector2(u, u * 0.45), c + Vector2(-u, u * 0.45), col, w)
			hud.draw_line(c + Vector2(-u, u * 0.45), c + Vector2(-u * 0.5, u * 0.05), col, w)
			hud.draw_line(c + Vector2(-u, u * 0.45), c + Vector2(-u * 0.5, u * 0.85), col, w)
		"zoom":
			hud.draw_arc(c, u * 1.1, 0.0, TAU, 24, col, w)
			hud.draw_line(c + Vector2(-u * 1.5, 0), c + Vector2(u * 1.5, 0), col, maxf(2.0, w * 0.6))
			hud.draw_line(c + Vector2(0, -u * 1.5), c + Vector2(0, u * 1.5), col, maxf(2.0, w * 0.6))
		"sprint":
			hud.draw_line(c + Vector2(-u, -u * 0.8), c + Vector2(0, 0), col, w)
			hud.draw_line(c + Vector2(0, 0), c + Vector2(-u, u * 0.8), col, w)
			hud.draw_line(c + Vector2(u * 0.1, -u * 0.8), c + Vector2(u * 1.1, 0), col, w)
			hud.draw_line(c + Vector2(u * 1.1, 0), c + Vector2(u * 0.1, u * 0.8), col, w)
		"pause":
			hud.draw_rect(Rect2(c + Vector2(-u * 0.55, -u * 0.7), Vector2(u * 0.4, u * 1.4)), col)
			hud.draw_rect(Rect2(c + Vector2(u * 0.15, -u * 0.7), Vector2(u * 0.4, u * 1.4)), col)


func _toggle_stance(s: int) -> void:
	if player != null and player.alive:
		player.stance = 0 if player.stance == s else s


func _btns() -> Array:
	var vs := get_viewport().get_visible_rect().size
	var k := vs.y / 720.0
	var out: Array = []
	for n in DEF_LAYOUT:
		var l: Dictionary = layout[n]
		var base: float = DEF_LAYOUT[n]["r"]
		var ic: String = "fire" if n == "fire2" else n
		out.append([n, Vector2(float(l["x"]) * vs.x, float(l["y"]) * vs.y), base * float(l["s"]) * k, ic, float(l["a"])])
	return out


func _btn_at(p: Vector2) -> String:
	var best := ""
	var bd := 1e9
	for b in _btns():
		var d: float = p.distance_to(b[1])
		if d <= float(b[2]) + 8.0 and d < bd:
			bd = d
			best = b[0]
	return best


func _btn_down(n: String) -> void:
	if n == "pause":
		_show_menu("PAUZA")
		return
	if player == null or not player.alive:
		return
	match n:
		"fire", "fire2":
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
		"sprint":
			player.sprint = not player.sprint


func _input(e: InputEvent) -> void:
	if state == S.EDIT:
		_edit_input(e)
		return
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
			KEY_SHIFT:
				if player != null:
					player.sprint = not player.sprint
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
				btn_ids.erase(e.index)
				var vals: Array = btn_ids.values()
				touch_fire = vals.has("fire") or vals.has("fire2")
			if e.index == stick_id:
				stick_id = -1
				stick_vec = Vector2.ZERO
			if e.index == look_id:
				look_id = -1
	elif e is InputEventScreenDrag:
		if e.index == stick_id:
			stick_vec = ((e.position - stick_origin) / 70.0).limit_length(1.0)
		elif e.index == look_id and player != null:
			var sens := (0.45 if zoomed else 1.0) * float(cfg["sens"])
			player.yaw -= e.relative.x * 0.0065 * sens
			player.pitch = clampf(player.pitch - e.relative.y * 0.005 * sens, -1.0, 1.0)


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
	var vs := get_viewport().get_visible_rect().size
	if state == S.EDIT:
		hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.45))
		for b in _btns():
			_draw_button(b, false, b[0] == edit_sel)
		return
	if state == S.MENU or player == null:
		return
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
		hud.draw_circle(stick_origin, 80.0, Color(1, 1, 1, 0.14))
		hud.draw_arc(stick_origin, 80.0, 0.0, TAU, 32, Color(1, 1, 1, 0.4), 3.0)
		hud.draw_circle(stick_origin + stick_vec * 80.0, 34.0, Color(1, 1, 1, 0.45))
	var down: Array = btn_ids.values()
	for b in _btns():
		var on: bool = down.has(b[0])
		if b[0] == "zoom" and zoomed:
			on = true
		if b[0] == "sprint" and player.sprint:
			on = true
		_draw_button(b, on, false)


func _draw_button(b: Array, on: bool, sel: bool) -> void:
	var a: float = b[4]
	var pos: Vector2 = b[1]
	var r: float = b[2]
	hud.draw_circle(pos, r, Color(0.05, 0.06, 0.09, minf(0.9, a * (1.4 if on else 0.9))))
	var ring := Color(1.0, 0.8, 0.2, 0.95) if (on or sel) else Color(1, 1, 1, minf(1.0, a + 0.3))
	hud.draw_arc(pos, r, 0.0, TAU, 40, ring, 4.0 if sel else 3.0)
	var ic := Color(1.0, 0.8, 0.2, 1.0) if on else Color(1, 1, 1, minf(1.0, a + 0.45))
	_icon(b[3], pos, r, ic)


