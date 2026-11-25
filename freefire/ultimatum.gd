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
const CFG_KEYS := ["sens", "vol", "assist", "autofire", "name", "tag", "quality", "fps", "showfps", "minimap", "diff", "kills", "wins", "games", "fav", "autopick", "music"]
const FPS_OPTS := [30, 45, 60, 90, 120]
const MAP_CRATES := [
	[Vector3(-6, 0.75, 6), Vector3(3, 1.5, 3)],
	[Vector3(6, 1, 2), Vector3(2, 2, 5)],
	[Vector3(0, 0.6, -2), Vector3(5, 1.2, 1.2)],
	[Vector3(-9, 1, -6), Vector3(2.5, 2, 2.5)],
	[Vector3(9, 0.75, -9), Vector3(3, 1.5, 3)],
	[Vector3(-2, 1, -12), Vector3(5, 2, 1.2)],
	[Vector3(-14, 1, 0), Vector3(1.2, 2, 6)],
	[Vector3(14, 1, 4), Vector3(1.2, 2, 6)],
]
const GUN_ICONS := {
	"ar": [[0.02, 0.38, 0.52, 0.46], [0.28, 0.30, 0.78, 0.54], [0.74, 0.34, 0.98, 0.56], [0.40, 0.54, 0.50, 0.86], [0.58, 0.54, 0.66, 0.76], [0.50, 0.22, 0.64, 0.30]],
	"smg": [[0.08, 0.40, 0.40, 0.48], [0.30, 0.32, 0.80, 0.54], [0.78, 0.36, 0.98, 0.52], [0.46, 0.54, 0.55, 0.90], [0.62, 0.54, 0.70, 0.76]],
	"sniper": [[0.00, 0.40, 0.62, 0.46], [0.30, 0.34, 0.80, 0.54], [0.78, 0.30, 0.98, 0.60], [0.34, 0.14, 0.60, 0.30], [0.44, 0.54, 0.52, 0.76], [0.62, 0.54, 0.70, 0.80]],
	"shotgun": [[0.00, 0.36, 0.62, 0.44], [0.00, 0.46, 0.58, 0.52], [0.30, 0.40, 0.46, 0.58], [0.58, 0.36, 0.78, 0.56], [0.76, 0.38, 0.98, 0.62]],
	"lmg": [[0.00, 0.38, 0.38, 0.46], [0.26, 0.28, 0.80, 0.56], [0.78, 0.34, 0.98, 0.58], [0.40, 0.56, 0.62, 0.90], [0.66, 0.56, 0.74, 0.78]],
	"pistol": [[0.20, 0.32, 0.80, 0.50], [0.30, 0.50, 0.50, 0.88], [0.52, 0.50, 0.62, 0.64]],
}
var cfg := {"sens": 1.0, "vol": 1.0, "assist": 1.0, "autofire": true, "name": "Player", "tag": "", "quality": 1, "fps": 2, "showfps": false, "minimap": true, "diff": 1, "kills": 0, "wins": 0, "games": 0, "fav": 0, "autopick": false, "music": true}
var sun: DirectionalLight3D
var chars: Array = []
var sel_char := 0
var char_btn: Button
var drag_t := 0.0
var music_p: AudioStreamPlayer
var lobby: Control
var stage: Node3D
var sc_f = null
var sc_t := 0.0
var ui_k := 1.0
var sel_mode := 1
var lobby_btn: Button
var lb_name: Label
var lb_lvl: Label
var lb_xp: ColorRect
var lb_char: Label
var lb_result: Label
var char_panel: Panel
var char_list: VBoxContainer
var arsenal_panel: Panel
var ars_sel := 0
var ars_name: Label
var ars_icon: Control
var ars_bars: Array = []
var mode_b: Array = []
var diff_b: Array = []
var hit_src = null
var hit_t := 0.0
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
	music_p = AudioStreamPlayer.new()
	music_p.volume_db = -17.0
	add_child(music_p)
	_load_settings()
	_build_world()
	_build_ui()
	_build_stage()
	_apply_graphics()
	_show_menu("ZONA: ULTIMATUM")


func _ld(n: String):
	for ext in [".ogg", ".wav"]:
		var p := "res://freefire/audio/%s%s" % [n, ext]
		if ResourceLoader.exists(p):
			return load(p)
	return Fighter.synth(n)


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
	var crates := MAP_CRATES
	for c in crates:
		_box(c[0], c[1], Color(0.6, 0.45, 0.28))
	sun = DirectionalLight3D.new()
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
	char_btn = Button.new()
	char_btn.custom_minimum_size = Vector2(320, 80)
	char_btn.add_theme_font_size_override("font_size", 30)
	char_btn.pressed.connect(_next_char)
	vb.add_child(char_btn)
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
	lobby_btn = Button.new()
	lobby_btn.text = "LOBBIGA"
	lobby_btn.custom_minimum_size = Vector2(320, 90)
	lobby_btn.add_theme_font_size_override("font_size", 34)
	lobby_btn.pressed.connect(_show_menu.bind("ZONA: ULTIMATUM"))
	vb.add_child(lobby_btn)
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
	_build_lobby()
	_build_extra_ui()


func _scan_chars() -> void:
	chars = []
	for fn in DirAccess.get_files_at("res://freefire/models"):
		var n: String = fn.trim_suffix(".remap").trim_suffix(".import")
		if (n.ends_with(".fbx") or n.ends_with(".glb") or n.ends_with(".gltf")) and not n.begins_with("SKM_") and not chars.has(n):
			chars.append(n)
	chars.sort()
	sel_char = clampi(sel_char, 0, maxi(chars.size() - 1, 0))


func _refresh_char_btn() -> void:
	if chars.is_empty():
		char_btn.text = "PERSONAJ: standart"
	else:
		char_btn.text = "PERSONAJ: " + str(chars[sel_char]).get_basename()


func _next_char() -> void:
	if chars.is_empty():
		return
	sel_char = (sel_char + 1) % chars.size()
	_refresh_char_btn()


func _my_name() -> String:
	var t := str(cfg["tag"]).strip_edges()
	var n := str(cfg["name"]).strip_edges()
	if n == "":
		n = "Player"
	return ("[%s] %s" % [t, n]) if t != "" else n


func _show_menu(title: String) -> void:
	_scan_chars()
	_refresh_char_btn()
	menu_title.text = title
	pick_panel.visible = false
	settings_panel.visible = false
	edit_panel.visible = false
	resume_btn.visible = (title == "PAUZA")
	lobby_btn.visible = (title == "PAUZA")
	state = S.MENU
	if title == "PAUZA":
		menu_panel.visible = true
		_hide_lobby()
	else:
		menu_panel.visible = false
		_show_lobby(title)


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
	_hide_lobby()
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
			if not chars.is_empty():
				var ci: int = sel_char if (t == 0 and k == 0) else randi() % chars.size()
				f.set_character("res://freefire/models/" + str(chars[ci]))
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
	if state == S.PICK and bool(cfg["autopick"]):
		_on_pick(clampi(int(cfg["fav"]), 0, WeaponDB.W.size() - 1))


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
		return _my_name()
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
		if attacker != null:
			hit_src = attacker
			hit_t = 1.0
	if target.hp <= 0:
		if attacker == player:
			cfg["kills"] = int(cfg["kills"]) + 1
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
	var jit: float = [0.06, 0.03, 0.012][clampi(int(cfg["diff"]), 0, 2)]
	b.aim_dir = ((aim_pt - b.eye()).normalized() + Vector3(randf_range(-jit, jit), randf_range(-jit, jit), randf_range(-jit, jit))).normalized()
	b.want_fire = dist < 45.0 and facing.dot(flat.normalized()) > 0.9


# ---------- oyinchi ----------
func _player_input(delta: float) -> void:
	var p = player
	drag_t = maxf(drag_t - delta, 0.0)
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
	var eye_p: Vector3 = p.eye()
	var db: Vector3 = (best.aim_point(false) - eye_p).normalized()
	var dh: Vector3 = (best.aim_point(true) - eye_p).normalized()
	var ty := atan2(-db.x, -db.z)
	var lo: float = asin(clampf(db.y, -1.0, 1.0))
	var hi: float = asin(clampf(dh.y, -1.0, 1.0)) + clampf(0.08 - 0.05 * a, -0.06, 0.06)
	hi = maxf(hi, lo + 0.01)
	var k := clampf(6.0 * a * delta, 0.0, 1.0)
	p.yaw = lerp_angle(p.yaw, ty, k * (0.25 if drag_t > 0.0 else 1.0))
	if p.pitch < lo:
		p.pitch = lerpf(p.pitch, lo, k)
	elif p.pitch > hi:
		p.pitch = lerpf(p.pitch, hi, k)


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
				for k in CFG_KEYS:
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
		var d := {"layout": layout}
		for kk in CFG_KEYS:
			d[kk] = cfg[kk]
		f.store_string(JSON.stringify(d))


func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(cfg["vol"]), 0.001)))


func _set_cfg(key: String, v) -> void:
	cfg[key] = v
	if key == "vol":
		_apply_volume()
	if key == "music" and not bool(v) and music_p != null:
		music_p.stop()
	if key == "quality" or key == "fps":
		_apply_graphics()


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
	b.pressed.connect(_ui_click)
	b.pressed.connect(cb)
	return b


func _ui_click() -> void:
	sfx2d.stream = _ld("ui")
	sfx2d.volume_db = -8.0
	if sfx2d.stream != null:
		sfx2d.play()


func _section(t: String) -> Label:
	var l := _lab(t, 24)
	l.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	return l


func _check_row(parent: Control, title: String, key: String) -> void:
	var cb := CheckButton.new()
	cb.text = title
	cb.button_pressed = bool(cfg[key])
	cb.add_theme_font_size_override("font_size", 24)
	cb.toggled.connect(func(on: bool): _set_cfg(key, on))
	parent.add_child(cb)


func _text_row(parent: Control, title: String, key: String, maxlen: int) -> void:
	parent.add_child(_lab(title, 24))
	var le := LineEdit.new()
	le.text = str(cfg[key])
	le.max_length = maxlen
	le.custom_minimum_size = Vector2(560, 60)
	le.add_theme_font_size_override("font_size", 28)
	le.text_changed.connect(func(t: String): _set_cfg(key, t))
	parent.add_child(le)


func _choice_row(parent: Control, title: String, key: String, labels: Array) -> void:
	parent.add_child(_lab(title, 24))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var grp := ButtonGroup.new()
	for i in range(labels.size()):
		var b := Button.new()
		b.text = str(labels[i])
		b.toggle_mode = true
		b.button_group = grp
		b.button_pressed = (int(cfg[key]) == i)
		b.custom_minimum_size = Vector2(110, 64)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(_set_cfg.bind(key, i))
		hb.add_child(b)
	parent.add_child(hb)


func _apply_graphics() -> void:
	var q: int = clampi(int(cfg["quality"]), 0, 2)
	Engine.max_fps = int(FPS_OPTS[clampi(int(cfg["fps"]), 0, 4)])
	var vp := get_viewport()
	vp.scaling_3d_scale = [0.6, 0.8, 1.0][q]
	vp.msaa_3d = Viewport.MSAA_2X if q == 2 else Viewport.MSAA_DISABLED
	if sun != null:
		sun.shadow_enabled = q >= 1
	if cam != null:
		cam.far = [50.0, 80.0, 140.0][q]


func _build_extra_ui() -> void:
	settings_panel = PanelContainer.new()
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(700, 540)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 12)
	sv.custom_minimum_size = Vector2(660, 0)
	var st := _lab("SOZLAMALAR", 36)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(st)
	sv.add_child(_section("OʻYINCHI"))
	_text_row(sv, "Ism", "name", 12)
	_text_row(sv, "Teg (masalan ZNA)", "tag", 4)
	sv.add_child(_section("BOSHQARUV"))
	_slider_row(sv, "Burilish tezligi", 0.3, 2.5, 0.05, "sens")
	_slider_row(sv, "Nishonga yordam (kam: bosh oson, koʻp: qorin)", 0.0, 2.0, 0.1, "assist")
	_check_row(sv, "Avto-otish (nishon dushmanda boʻlsa)", "autofire")
	sv.add_child(_mini_btn("TUGMALARNI JOYLASHTIRISH", _edit_start, 560.0))
	sv.add_child(_section("GRAFIKA"))
	_choice_row(sv, "Sifat (past = tez, kuchsiz telefon uchun)", "quality", ["Past", "Oʻrta", "Yuqori"])
	_choice_row(sv, "FPS chegarasi", "fps", ["30", "45", "60", "90", "120"])
	_check_row(sv, "Xarita (minimap)", "minimap")
	_check_row(sv, "FPS koʻrsatish", "showfps")
	sv.add_child(_section("OVOZ VA BOTLAR"))
	_slider_row(sv, "Umumiy ovoz", 0.0, 1.0, 0.05, "vol")
	_check_row(sv, "Lobbi musiqasi", "music")
	_choice_row(sv, "Bot qiyinligi", "diff", ["Oson", "Oʻrta", "Qiyin"])
	sv.add_child(_mini_btn("SAQLASH VA ORQAGA", _close_settings, 560.0))
	sc.add_child(sv)
	settings_panel.add_child(sc)
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
	lobby.visible = false
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
		elif (e.index == look_id or str(btn_ids.get(e.index, "")) == "fire" or str(btn_ids.get(e.index, "")) == "fire2") and player != null:
			drag_t = 0.2
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
	if stage != null and stage.visible and sc_f != null and is_instance_valid(sc_f):
		sc_t += delta
		sc_f.rotation.y = PI + sin(sc_t * 0.6) * 0.5
		sc_f.lobby_pose()
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
				_record_result(score[0] >= 3)
				_show_menu("GʻALABA!" if score[0] >= 3 else "Magʻlubiyat")
				lbl_msg.text = ""
			else:
				round_i += 1
				_begin_round()
	if player != null and state != S.MENU:
		_update_cam()
		lbl_top.text = "Raund %d/5     %d : %d     %d s" % [mini(round_i + 1, 5), score[0], score[1], int(ceil(maxf(round_t, 0.0)))]
		lbl_w.text = ""
		lbl_hp.text = ""
	else:
		lbl_top.text = ""
		lbl_w.text = ""
		lbl_hp.text = ""
	dmg_t = maxf(dmg_t - delta, 0.0)
	hit_t = maxf(hit_t - delta, 0.0)
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
	var k := vs.y / 720.0
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
	_draw_hit_dir(c, k)
	var top_y := 14.0 * k
	if bool(cfg["minimap"]):
		_draw_minimap(k)
		top_y += 198.0 * k
	top_y = _draw_squad(k, top_y)
	_draw_weapon_panel(vs, k)
	_draw_hp(vs, k)
	var fy := top_y + 10.0 * k
	for i in range(feed.size()):
		hud.draw_string(ThemeDB.fallback_font, Vector2(14.0 * k, fy + 22.0 * k + i * 26.0 * k), str(feed[i]["s"]), HORIZONTAL_ALIGNMENT_LEFT, 520.0 * k, int(20.0 * k))
	if bool(cfg["showfps"]):
		hud.draw_string(ThemeDB.fallback_font, Vector2(vs.x * 0.5 - 40.0 * k, vs.y - 12.0 * k), "FPS %d" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, int(20.0 * k), Color(1, 1, 1, 0.7))
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


func _draw_hit_dir(c: Vector2, k: float) -> void:
	if hit_t <= 0.0 or hit_src == null or not is_instance_valid(hit_src):
		return
	var d: Vector3 = hit_src.global_position - player.global_position
	var f2 := Vector2(-sin(player.yaw), -cos(player.yaw))
	var r2 := Vector2(cos(player.yaw), -sin(player.yaw))
	var dv := Vector2(d.x, d.z).normalized()
	var ang := Vector2(dv.dot(r2), -dv.dot(f2)).angle()
	hud.draw_arc(c, 170.0 * k, ang - 0.35, ang + 0.35, 14, Color(1, 0.1, 0.1, clampf(hit_t, 0.0, 1.0)), 10.0 * k)


func _w2m(x: float, z: float, o: Vector2, s: float) -> Vector2:
	return o + Vector2((x + 24.0) / 48.0 * s, (z + 24.0) / 48.0 * s)


func _draw_minimap(k: float) -> void:
	var s := 190.0 * k
	var o := Vector2(14.0 * k, 14.0 * k)
	hud.draw_rect(Rect2(o, Vector2(s, s)), Color(0.04, 0.05, 0.07, 0.62))
	for cr in MAP_CRATES:
		var p: Vector3 = cr[0]
		var sz: Vector3 = cr[1]
		var a := _w2m(p.x - sz.x * 0.5, p.z - sz.z * 0.5, o, s)
		hud.draw_rect(Rect2(a, Vector2(sz.x, sz.z) / 48.0 * s), Color(0.55, 0.5, 0.42, 0.9))
	hud.draw_rect(Rect2(o, Vector2(s, s)), Color(1, 1, 1, 0.55), false, 2.0)
	for f in fighters:
		if f == player or not f.alive:
			continue
		var pos := _w2m(f.global_position.x, f.global_position.z, o, s)
		if f.team == player.team:
			hud.draw_circle(pos, 5.0 * k, Color(0.3, 1.0, 0.4))
		elif f.fired_t > 0.0:
			hud.draw_circle(pos, 6.0 * k, Color(1.0, 0.15, 0.15, clampf(f.fired_t, 0.25, 1.0)))
	var pp := _w2m(player.global_position.x, player.global_position.z, o, s)
	var dir := Vector2(-sin(player.yaw), -cos(player.yaw))
	var cone := PackedVector2Array([pp, pp + dir.rotated(-0.5) * 62.0 * k, pp + dir.rotated(0.5) * 62.0 * k])
	hud.draw_colored_polygon(cone, Color(1, 1, 1, 0.28))
	var arrow := PackedVector2Array([pp + dir * 10.0 * k, pp + dir.rotated(2.5) * 8.0 * k, pp + dir.rotated(-2.5) * 8.0 * k])
	hud.draw_colored_polygon(arrow, Color(0.2, 0.85, 1.0))


func _draw_squad(k: float, y0: float) -> float:
	var font := ThemeDB.fallback_font
	var y := y0
	var list: Array = [player]
	for f in fighters:
		if f != player and f.team == player.team:
			list.append(f)
	var idx := 1
	for f in list:
		var h := 40.0 * k
		hud.draw_rect(Rect2(Vector2(14.0 * k, y), Vector2(250.0 * k, h)), Color(0, 0, 0, 0.5))
		var accent := Color(0.3, 1.0, 0.4) if f.alive else Color(0.6, 0.2, 0.2)
		hud.draw_rect(Rect2(Vector2(14.0 * k, y), Vector2(4.0 * k, h)), accent)
		hud.draw_string(font, Vector2(26.0 * k, y + 28.0 * k), str(idx), HORIZONTAL_ALIGNMENT_LEFT, -1, int(24.0 * k))
		var nm: String = _my_name() if f == player else "Doʻst"
		hud.draw_string(font, Vector2(52.0 * k, y + 19.0 * k), nm, HORIZONTAL_ALIGNMENT_LEFT, 200.0 * k, int(18.0 * k))
		hud.draw_rect(Rect2(Vector2(52.0 * k, y + 26.0 * k), Vector2(200.0 * k, 6.0 * k)), Color(1, 1, 1, 0.15))
		hud.draw_rect(Rect2(Vector2(52.0 * k, y + 26.0 * k), Vector2(200.0 * k * clampf(float(f.hp) / 200.0, 0.0, 1.0), 6.0 * k)), accent)
		y += h + 4.0 * k
		idx += 1
	return y


func _gun_icon(kind: String, r: Rect2, col: Color, cv: CanvasItem = null) -> void:
	var cnv: CanvasItem = cv if cv != null else hud
	var parts: Array = GUN_ICONS.get(kind, GUN_ICONS["ar"])
	for p in parts:
		var x0 := float(p[0])
		var y0 := float(p[1])
		var x1 := float(p[2])
		var y1 := float(p[3])
		cnv.draw_rect(Rect2(r.position + Vector2(x0 * r.size.x, y0 * r.size.y), Vector2((x1 - x0) * r.size.x, (y1 - y0) * r.size.y)), col)


func _draw_weapon_panel(vs: Vector2, k: float) -> void:
	var font := ThemeDB.fallback_font
	var w := 300.0 * k
	var o := Vector2(vs.x - w - 14.0 * k, 92.0 * k)
	var wd: Dictionary = WeaponDB.W[player.wid]
	var reloading: bool = player.rl > 0.0
	var amber := Color(1.0, 0.78, 0.2, 0.95)
	hud.draw_rect(Rect2(o, Vector2(w, 88.0 * k)), Color(0.03, 0.04, 0.06, 0.72))
	hud.draw_rect(Rect2(o, Vector2(w, 88.0 * k)), amber, false, 2.5)
	var ms := str(player.mag)
	hud.draw_string(font, o + Vector2(12.0 * k, 46.0 * k), ms, HORIZONTAL_ALIGNMENT_LEFT, -1, int(46.0 * k), Color.WHITE)
	var rx := 14.0 * k + float(ms.length()) * 25.0 * k
	hud.draw_string(font, o + Vector2(rx, 46.0 * k), "/" + str(int(player.slot_res[player.slot])), HORIZONTAL_ALIGNMENT_LEFT, -1, int(24.0 * k), Color(1, 1, 1, 0.65))
	var nm: String = "ZARYADLANMOQDA" if reloading else str(wd["n"])
	hud.draw_string(font, o + Vector2(12.0 * k, 70.0 * k), nm, HORIZONTAL_ALIGNMENT_LEFT, w * 0.55, int(18.0 * k), amber if reloading else Color.WHITE)
	_gun_icon(str(wd["s"]), Rect2(o + Vector2(w * 0.52, 8.0 * k), Vector2(w * 0.44, 50.0 * k)), Color(1, 1, 1, 0.92))
	var frac := 1.0
	if reloading:
		frac = 1.0 - clampf(player.rl / float(wd["rl"]), 0.0, 1.0)
	else:
		frac = clampf(float(player.mag) / float(wd["mag"]), 0.0, 1.0)
	hud.draw_rect(Rect2(o + Vector2(12.0 * k, 77.0 * k), Vector2(w - 24.0 * k, 6.0 * k)), Color(1, 1, 1, 0.18))
	hud.draw_rect(Rect2(o + Vector2(12.0 * k, 77.0 * k), Vector2((w - 24.0 * k) * frac, 6.0 * k)), amber)
	var tw := (w - 8.0 * k) * 0.5
	for i in range(2):
		var t0 := o + Vector2(float(i) * (tw + 8.0 * k), 96.0 * k)
		var wi: Dictionary = WeaponDB.W[player.slot_wid[i]]
		var act: bool = (i == player.slot)
		hud.draw_rect(Rect2(t0, Vector2(tw, 50.0 * k)), Color(0.03, 0.04, 0.06, 0.72))
		hud.draw_rect(Rect2(t0, Vector2(tw, 50.0 * k)), amber if act else Color(1, 1, 1, 0.35), false, 2.0)
		_gun_icon(str(wi["s"]), Rect2(t0 + Vector2(6.0 * k, 4.0 * k), Vector2(tw - 12.0 * k, 28.0 * k)), Color(1, 1, 1, 0.9 if act else 0.6))
		hud.draw_string(font, t0 + Vector2(8.0 * k, 46.0 * k), str(int(player.slot_res[i])), HORIZONTAL_ALIGNMENT_LEFT, -1, int(16.0 * k), Color(1, 1, 1, 0.8))


func _draw_hp(vs: Vector2, k: float) -> void:
	var o := Vector2(14.0 * k, vs.y - 50.0 * k)
	var fr := clampf(float(player.hp) / 200.0, 0.0, 1.0)
	var col := Color(0.3, 0.9, 0.35) if player.hp > 100 else (Color(1.0, 0.8, 0.2) if player.hp > 50 else Color(1.0, 0.25, 0.2))
	hud.draw_rect(Rect2(o, Vector2(260.0 * k, 24.0 * k)), Color(0, 0, 0, 0.55))
	hud.draw_rect(Rect2(o, Vector2(260.0 * k * fr, 24.0 * k)), col)
	hud.draw_string(ThemeDB.fallback_font, o + Vector2(8.0 * k, 19.0 * k), "%d" % player.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20.0 * k), Color.WHITE)


func _draw_button(b: Array, on: bool, sel: bool) -> void:
	var a: float = b[4]
	var pos: Vector2 = b[1]
	var r: float = b[2]
	hud.draw_circle(pos, r, Color(0.05, 0.06, 0.09, minf(0.9, a * (1.4 if on else 0.9))))
	var ring := Color(1.0, 0.8, 0.2, 0.95) if (on or sel) else Color(1, 1, 1, minf(1.0, a + 0.3))
	hud.draw_arc(pos, r, 0.0, TAU, 40, ring, 4.0 if sel else 3.0)
	var ic := Color(1.0, 0.8, 0.2, 1.0) if on else Color(1, 1, 1, minf(1.0, a + 0.45))
	_icon(b[3], pos, r, ic)


# ---------- LOBBI ----------
func _sbox(bg: Color, border: Color, bw: int = 2, r: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(r)
	s.content_margin_left = 12.0
	s.content_margin_right = 12.0
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	return s


func _style_btn(b: Button, gold: bool) -> void:
	var bg := Color(0.95, 0.70, 0.10, 0.96) if gold else Color(0.08, 0.07, 0.14, 0.85)
	var bd := Color(1.0, 0.88, 0.35) if gold else Color(0.75, 0.6, 0.2, 0.9)
	b.add_theme_stylebox_override("normal", _sbox(bg, bd))
	b.add_theme_stylebox_override("hover", _sbox(bg.lightened(0.1), bd))
	b.add_theme_stylebox_override("pressed", _sbox(bg.lightened(0.25), bd))
	b.add_theme_stylebox_override("focus", _sbox(bg, bd))
	var fc := Color(0.12, 0.07, 0.0) if gold else Color.WHITE
	for nm in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(nm, fc)


func _mkbtn(text: String, sz: int, pos: Vector2, size: Vector2, gold: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = size
	b.size = size
	b.add_theme_font_size_override("font_size", sz)
	_style_btn(b, gold)
	b.pressed.connect(cb)
	return b


func _gold_lab(txt: String, sz: int) -> Label:
	var l := _lab(txt, sz)
	l.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	return l


func _build_lobby() -> void:
	var vs := get_viewport().get_visible_rect().size
	var k := vs.y / 720.0
	ui_k = k
	lobby = Control.new()
	lobby.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(lobby)
	lobby.visible = false
	# profil kartasi
	var pc := Panel.new()
	pc.position = Vector2(14, 12) * k
	pc.size = Vector2(340, 84) * k
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_theme_stylebox_override("panel", _sbox(Color(0.05, 0.04, 0.1, 0.82), Color(0.75, 0.6, 0.2, 0.9)))
	lobby.add_child(pc)
	lb_name = _lab("", int(24 * k))
	lb_name.position = Vector2(12, 4) * k
	pc.add_child(lb_name)
	lb_lvl = _gold_lab("", int(16 * k))
	lb_lvl.position = Vector2(12, 38) * k
	pc.add_child(lb_lvl)
	var xb := ColorRect.new()
	xb.color = Color(1, 1, 1, 0.15)
	xb.position = Vector2(12, 68) * k
	xb.size = Vector2(316, 8) * k
	pc.add_child(xb)
	lb_xp = ColorRect.new()
	lb_xp.color = Color(1.0, 0.8, 0.25)
	lb_xp.position = Vector2(12, 68) * k
	lb_xp.size = Vector2(10, 8) * k
	pc.add_child(lb_xp)
	lb_result = _gold_lab("", int(44 * k))
	lb_result.position = Vector2(vs.x * 0.5 - 300 * k, 14 * k)
	lb_result.custom_minimum_size = Vector2(600, 0) * k
	lb_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby.add_child(lb_result)
	# chap tugmalar
	var names := ["PERSONAJ", "QUROLLAR", "SOZLAMALAR"]
	var cbs := [_lb_char_toggle, _lb_arsenal_toggle, _open_settings]
	for i in range(3):
		lobby.add_child(_mkbtn(names[i], int(24 * k), Vector2(14, 112 + i * 66) * k, Vector2(250, 56) * k, false, cbs[i]))
	# personaj almashtirish
	var cx := vs.x * 0.40
	lobby.add_child(_mkbtn("<", int(34 * k), Vector2(cx - 200 * k, vs.y - 128 * k), Vector2(64, 64) * k, false, _lb_prev))
	lobby.add_child(_mkbtn(">", int(34 * k), Vector2(cx + 136 * k, vs.y - 128 * k), Vector2(64, 64) * k, false, _lb_next))
	lb_char = _lab("", int(24 * k))
	lb_char.position = Vector2(cx - 130 * k, vs.y - 118 * k)
	lb_char.custom_minimum_size = Vector2(260 * k, 0)
	lb_char.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby.add_child(lb_char)
	# rejim paneli
	var mp := Panel.new()
	mp.position = Vector2(vs.x - 390 * k, vs.y - 268 * k)
	mp.size = Vector2(370, 150) * k
	mp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp.add_theme_stylebox_override("panel", _sbox(Color(0.05, 0.04, 0.1, 0.82), Color(0.75, 0.6, 0.2, 0.9)))
	lobby.add_child(mp)
	var mt := _gold_lab("REJIM  (5 raund, 3 gʻalaba)", int(18 * k))
	mt.position = Vector2(12, 6) * k
	mp.add_child(mt)
	mode_b = []
	for i in range(2):
		var mb := _mkbtn("%d VA %d" % [i + 1, i + 1], int(24 * k), Vector2(12 + i * 178, 36) * k, Vector2(168, 46) * k, false, _lb_mode.bind(i + 1))
		mp.add_child(mb)
		mode_b.append(mb)
	var dt := _lab("Bot qiyinligi", int(16 * k))
	dt.position = Vector2(12, 88) * k
	mp.add_child(dt)
	diff_b = []
	var dn := ["Oson", "Oʻrta", "Qiyin"]
	for i in range(3):
		var db := _mkbtn(dn[i], int(18 * k), Vector2(12 + i * 118, 108) * k, Vector2(110, 36) * k, false, _lb_diff.bind(i))
		mp.add_child(db)
		diff_b.append(db)
	lobby.add_child(_mkbtn("BOSHLASH", int(46 * k), Vector2(vs.x - 390 * k, vs.y - 108 * k), Vector2(370, 96) * k, true, _lb_start))
	# personaj roʻyxati
	char_panel = Panel.new()
	char_panel.position = Vector2(vs.x - 390 * k, 104 * k)
	char_panel.size = Vector2(370, 330) * k
	char_panel.add_theme_stylebox_override("panel", _sbox(Color(0.05, 0.04, 0.1, 0.92), Color(0.75, 0.6, 0.2, 0.9)))
	lobby.add_child(char_panel)
	var csc := ScrollContainer.new()
	csc.position = Vector2(8, 8) * k
	csc.size = Vector2(354, 314) * k
	csc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	char_panel.add_child(csc)
	char_list = VBoxContainer.new()
	char_list.custom_minimum_size = Vector2(340, 0) * k
	char_list.add_theme_constant_override("separation", 8)
	csc.add_child(char_list)
	char_panel.visible = false
	# qurollar oynasi
	arsenal_panel = Panel.new()
	arsenal_panel.position = Vector2(vs.x * 0.5 - 380 * k, 50 * k)
	arsenal_panel.size = Vector2(760, 620) * k
	arsenal_panel.add_theme_stylebox_override("panel", _sbox(Color(0.04, 0.03, 0.09, 0.96), Color(0.75, 0.6, 0.2, 0.95), 3, 14))
	lobby.add_child(arsenal_panel)
	var at := _gold_lab("QUROLLAR", int(30 * k))
	at.position = Vector2(20, 10) * k
	arsenal_panel.add_child(at)
	var asc := ScrollContainer.new()
	asc.position = Vector2(16, 56) * k
	asc.size = Vector2(728, 270) * k
	asc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	arsenal_panel.add_child(asc)
	var ag := GridContainer.new()
	ag.columns = 5
	ag.add_theme_constant_override("h_separation", 6)
	ag.add_theme_constant_override("v_separation", 6)
	asc.add_child(ag)
	for i in range(WeaponDB.W.size()):
		var wb := Button.new()
		wb.text = str(WeaponDB.W[i]["n"])
		wb.custom_minimum_size = Vector2(138, 54) * k
		wb.add_theme_font_size_override("font_size", int(17 * k))
		_style_btn(wb, false)
		wb.pressed.connect(_ars_select.bind(i))
		ag.add_child(wb)
	ars_icon = Control.new()
	ars_icon.position = Vector2(20, 340) * k
	ars_icon.size = Vector2(270, 120) * k
	ars_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ars_icon.draw.connect(_draw_ars_icon)
	arsenal_panel.add_child(ars_icon)
	ars_name = _gold_lab("", int(24 * k))
	ars_name.position = Vector2(310, 334) * k
	arsenal_panel.add_child(ars_name)
	ars_bars = []
	var bn := ["Zarar", "Tezlik", "Zaryad"]
	for i in range(3):
		var bl := _lab(bn[i], int(18 * k))
		bl.position = Vector2(310, 380 + i * 34) * k
		arsenal_panel.add_child(bl)
		var pb := ProgressBar.new()
		pb.position = Vector2(430, 384 + i * 34) * k
		pb.size = Vector2(300, 20) * k
		pb.show_percentage = false
		pb.max_value = 100.0
		arsenal_panel.add_child(pb)
		ars_bars.append(pb)
	var ck := CheckButton.new()
	ck.text = "Har raund shu qurol bilan (so'ramasdan)"
	ck.position = Vector2(20, 484) * k
	ck.add_theme_font_size_override("font_size", int(20 * k))
	ck.button_pressed = bool(cfg["autopick"])
	ck.toggled.connect(func(on: bool): _set_cfg("autopick", on))
	arsenal_panel.add_child(ck)
	arsenal_panel.add_child(_mkbtn("TANLASH", int(26 * k), Vector2(20, 540) * k, Vector2(350, 60) * k, true, _ars_confirm))
	arsenal_panel.add_child(_mkbtn("YOPISH", int(26 * k), Vector2(390, 540) * k, Vector2(350, 60) * k, false, _lb_arsenal_toggle))
	arsenal_panel.visible = false


func _draw_ars_icon() -> void:
	var kind := str(WeaponDB.W[ars_sel]["s"])
	_gun_icon(kind, Rect2(Vector2.ZERO, ars_icon.size), Color(1, 1, 1, 0.95), ars_icon)


func _ars_select(i: int) -> void:
	ars_sel = i
	var w: Dictionary = WeaponDB.W[i]
	ars_name.text = "%s  (%s)" % [w["n"], str(w["s"]).to_upper()]
	ars_bars[0].value = minf(float(w["dmg"]) * float(w["pel"]), 100.0)
	ars_bars[1].value = minf(1.0 / float(w["rate"]) / 15.0 * 100.0, 100.0)
	ars_bars[2].value = minf(float(w["mag"]) / 50.0 * 100.0, 100.0)
	ars_icon.queue_redraw()


func _ars_confirm() -> void:
	cfg["fav"] = ars_sel
	_save_settings()
	arsenal_panel.visible = false
	_refresh_showcase()


func _lb_arsenal_toggle() -> void:
	arsenal_panel.visible = not arsenal_panel.visible
	char_panel.visible = false
	if arsenal_panel.visible:
		_ars_select(clampi(int(cfg["fav"]), 0, WeaponDB.W.size() - 1))


func _lb_char_toggle() -> void:
	char_panel.visible = not char_panel.visible
	arsenal_panel.visible = false


func _fill_char_panel() -> void:
	for c in char_list.get_children():
		c.queue_free()
	if chars.is_empty():
		var l := _lab("Personaj fayllari topilmadi", int(20 * ui_k))
		char_list.add_child(l)
		return
	for i in range(chars.size()):
		var b := Button.new()
		b.text = str(chars[i]).get_basename()
		b.custom_minimum_size = Vector2(330, 60) * ui_k
		b.add_theme_font_size_override("font_size", int(22 * ui_k))
		_style_btn(b, i == sel_char)
		b.pressed.connect(_lb_pick_char.bind(i))
		char_list.add_child(b)


func _lb_pick_char(i: int) -> void:
	sel_char = i
	char_panel.visible = false
	_refresh_lobby()
	_refresh_showcase()


func _lb_step(d: int) -> void:
	if chars.is_empty():
		return
	sel_char = (sel_char + d + chars.size()) % chars.size()
	_refresh_lobby()
	_refresh_showcase()


func _lb_prev() -> void:
	_lb_step(-1)


func _lb_next() -> void:
	_lb_step(1)


func _lb_mode(n: int) -> void:
	sel_mode = n
	_refresh_lobby()


func _lb_diff(d: int) -> void:
	_set_cfg("diff", d)
	_save_settings()
	_refresh_lobby()


func _lb_start() -> void:
	_save_settings()
	_start_match(sel_mode)


func _refresh_lobby() -> void:
	var xp := int(cfg["kills"]) * 10 + int(cfg["wins"]) * 50 + int(cfg["games"]) * 5
	lb_name.text = _my_name()
	lb_lvl.text = "DARAJA %d   KILL %d   GʻALABA %d" % [1 + xp / 100, int(cfg["kills"]), int(cfg["wins"])]
	lb_xp.size.x = maxf(316.0 * ui_k * float(xp % 100) / 100.0, 6.0)
	lb_char.text = "Standart" if chars.is_empty() else str(chars[sel_char]).get_basename()
	for i in range(mode_b.size()):
		_style_btn(mode_b[i], sel_mode == i + 1)
	for i in range(diff_b.size()):
		_style_btn(diff_b[i], int(cfg["diff"]) == i)


func _record_result(win: bool) -> void:
	cfg["games"] = int(cfg["games"]) + 1
	if win:
		cfg["wins"] = int(cfg["wins"]) + 1
	_save_settings()


func _build_stage() -> void:
	stage = Node3D.new()
	stage.position = Vector3(0, 0, -90)
	add_child(stage)
	var bg := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 40.0
	sph.height = 80.0
	bg.mesh = sph
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, cull_front;\nvarying float vy;\nvoid vertex() { vy = VERTEX.y; }\nvoid fragment() {\n\tfloat t = clamp(vy / 40.0 * 0.5 + 0.5, 0.0, 1.0);\n\tvec3 low = vec3(0.55, 0.22, 0.85);\n\tvec3 high = vec3(0.07, 0.03, 0.20);\n\tALBEDO = mix(low, high, pow(t, 0.7));\n}\n"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	bg.material_override = sm
	stage.add_child(bg)
	var fl := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 2.4
	cyl.height = 0.16
	fl.mesh = cyl
	fl.position = Vector3(0, -0.08, 0)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.10, 0.08, 0.18)
	fm.metallic = 0.6
	fm.roughness = 0.35
	fl.material_override = fm
	stage.add_child(fl)
	var ring := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 2.45
	rc.bottom_radius = 2.45
	rc.height = 0.05
	ring.mesh = rc
	ring.position = Vector3(0, -0.12, 0)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.8, 0.25)
	ring.material_override = rm
	stage.add_child(ring)
	var l1 := OmniLight3D.new()
	l1.position = Vector3(-2.5, 2.6, 2.0)
	l1.light_color = Color(1.0, 0.35, 0.9)
	l1.light_energy = 2.2
	l1.omni_range = 12.0
	stage.add_child(l1)
	var l2 := OmniLight3D.new()
	l2.position = Vector3(3.0, 2.2, 1.5)
	l2.light_color = Color(0.3, 0.8, 1.0)
	l2.light_energy = 2.0
	l2.omni_range = 12.0
	stage.add_child(l2)
	var l3 := OmniLight3D.new()
	l3.position = Vector3(0.5, 2.5, 4.0)
	l3.light_color = Color(1.0, 0.95, 0.9)
	l3.light_energy = 1.6
	l3.omni_range = 12.0
	stage.add_child(l3)
	stage.visible = false


func _refresh_showcase() -> void:
	if sc_f != null and is_instance_valid(sc_f):
		sc_f.queue_free()
	sc_f = Fighter.new()
	sc_f.setup(0, false)
	stage.add_child(sc_f)
	sc_f.set_physics_process(false)
	sc_f.set_process(false)
	sc_f.collision_layer = 0
	sc_f.collision_mask = 0
	sc_f.reset(stage.global_position + Vector3(0, 0.05, 0), 0.0)
	sc_f.give(clampi(int(cfg["fav"]), 0, WeaponDB.W.size() - 1))
	sc_f._build_gun()
	if not chars.is_empty():
		sc_f.set_character("res://freefire/models/" + str(chars[sel_char]))
	sc_f.rotation.y = PI


func _show_lobby(title: String) -> void:
	lobby.visible = true
	lb_result.text = "" if title == "ZONA: ULTIMATUM" else title
	char_panel.visible = false
	arsenal_panel.visible = false
	_fill_char_panel()
	_refresh_lobby()
	stage.visible = true
	cam.fov = 40.0
	cam.global_position = stage.global_position + Vector3(0.4, 1.3, 3.5)
	cam.look_at(stage.global_position + Vector3(0.4, 1.0, 0.0))
	_refresh_showcase()
	if bool(cfg["music"]) and music_p != null and not music_p.playing:
		if music_p.stream == null:
			music_p.stream = Fighter.synth("music")
		if music_p.stream != null:
			music_p.play()


func _hide_lobby() -> void:
	if music_p != null:
		music_p.stop()
	if lobby != null:
		lobby.visible = false
	if stage != null:
		stage.visible = false
	if sc_f != null and is_instance_valid(sc_f):
		sc_f.queue_free()
	sc_f = null
