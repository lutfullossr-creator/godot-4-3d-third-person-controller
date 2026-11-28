extends RefCounted
# Ilova ichidagi yangilanish: tekshirish, yuklab olish, GitHub'dan darhol so'rash.
# Lobbi yuqori o'ng burchagida "YANGILANISH" tugmasi qo'shadi.
# GitHub token faqat shu telefonda saqlanadi (user://zona_gh_token.txt).

const REPO := "lutfullossr-creator/godot-4-3d-third-person-controller"
const BASE_URL := "https://github.com/lutfullossr-creator/godot-4-3d-third-person-controller/releases/latest/download/"
const PATCH_INFO := "user://patch_info.json"
const ASSET_INFO := "user://assets_info.json"
const TOKEN_FILE := "user://zona_gh_token.txt"

var g = null
var uk := 1.0
var btn: Button = null
var panel: Panel = null
var lbl: Label = null
var bar: ProgressBar = null
var b_get: Button = null
var b_apk: Button = null
var b_quit: Button = null
var tok_edit: LineEdit = null
var remote := {}
var cur_run := 0
var base_here := ""
var assets_have := ""
var tried := {}
var polling := false
var poll_left := 0.0
var disp_time := 0
var last_check := -100000
var dl_http: HTTPRequest = null


func setup(game) -> void:
	g = game
	_read_state()


func _read_state() -> void:
	var bi = load("res://freefire/build_info.gd")
	if bi != null:
		cur_run = int(bi.RUN)
		base_here = str(bi.BASE)
	var pi := _read_json(PATCH_INFO)
	cur_run = maxi(cur_run, int(pi.get("run", 0)))
	assets_have = str(_read_json(ASSET_INFO).get("hash", ""))


func _read_json(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var v = JSON.parse_string(f.get_as_text())
	if v is Dictionary:
		return v
	return {}


func _write_json(p: String, d: Dictionary) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))


func _token() -> String:
	if not FileAccess.file_exists(TOKEN_FILE):
		return ""
	var f := FileAccess.open(TOKEN_FILE, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text().strip_edges()


func _sbox(bg: Color, border: Color, r: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(r)
	s.content_margin_left = 12.0
	s.content_margin_right = 12.0
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	return s


func _style(b: Button, gold: bool) -> void:
	var bg := Color(0.95, 0.70, 0.10, 0.96) if gold else Color(0.08, 0.07, 0.14, 0.88)
	var bd := Color(1.0, 0.88, 0.35) if gold else Color(0.75, 0.6, 0.2, 0.9)
	b.add_theme_stylebox_override("normal", _sbox(bg, bd))
	b.add_theme_stylebox_override("hover", _sbox(bg.lightened(0.1), bd))
	b.add_theme_stylebox_override("pressed", _sbox(bg.lightened(0.25), bd))
	b.add_theme_stylebox_override("focus", _sbox(bg, bd))
	var fc := Color(0.12, 0.07, 0.0) if gold else Color.WHITE
	for nm in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(nm, fc)


func _mk(parent: Control, text: String, pos: Vector2, size: Vector2, sz: int, gold: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos * uk
	b.size = size * uk
	b.custom_minimum_size = size * uk
	b.add_theme_font_size_override("font_size", int(float(sz) * uk))
	_style(b, gold)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func on_lobby_build(lobby: Control, k: float) -> void:
	uk = k
	var vs: Vector2 = g.get_viewport().get_visible_rect().size
	btn = Button.new()
	btn.text = "YANGILANISH"
	btn.position = Vector2(vs.x - 250.0 * k, 14.0 * k)
	btn.size = Vector2(236, 52) * k
	btn.custom_minimum_size = Vector2(236, 52) * k
	btn.add_theme_font_size_override("font_size", int(20.0 * k))
	_style(btn, false)
	btn.pressed.connect(_open)
	lobby.add_child(btn)
	panel = Panel.new()
	panel.size = Vector2(660, 450) * k
	panel.position = Vector2((vs.x - 660.0 * k) * 0.5, (vs.y - 450.0 * k) * 0.5)
	panel.add_theme_stylebox_override("panel", _sbox(Color(0.04, 0.03, 0.09, 0.97), Color(0.75, 0.6, 0.2, 0.95), 14))
	lobby.add_child(panel)
	var title := Label.new()
	title.text = "YANGILANISH"
	title.position = Vector2(20, 10) * k
	title.add_theme_font_size_override("font_size", int(30.0 * k))
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	panel.add_child(title)
	lbl = Label.new()
	lbl.position = Vector2(20, 58) * k
	lbl.size = Vector2(620, 120) * k
	lbl.custom_minimum_size = Vector2(620, 0) * k
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", int(20.0 * k))
	panel.add_child(lbl)
	bar = ProgressBar.new()
	bar.position = Vector2(20, 182) * k
	bar.size = Vector2(620, 18) * k
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.visible = false
	panel.add_child(bar)
	_mk(panel, "TEKSHIRISH", Vector2(20, 212), Vector2(190, 50), 20, false, _check_manual)
	b_get = _mk(panel, "YUKLAB OLISH", Vector2(220, 212), Vector2(200, 50), 20, true, _download)
	_mk(panel, "GITHUB'DAN SO'RASH", Vector2(430, 212), Vector2(210, 50), 17, false, _ask)
	b_apk = _mk(panel, "APK YUKLASH", Vector2(20, 272), Vector2(300, 46), 20, true, _open_apk)
	b_quit = _mk(panel, "ILOVANI YOPISH", Vector2(330, 272), Vector2(310, 46), 20, true, _quit)
	b_get.visible = false
	b_apk.visible = false
	b_quit.visible = false
	var tl := Label.new()
	tl.text = "GitHub token (bir marta kiritiladi):"
	tl.position = Vector2(20, 326) * k
	tl.add_theme_font_size_override("font_size", int(16.0 * k))
	panel.add_child(tl)
	tok_edit = LineEdit.new()
	tok_edit.secret = true
	tok_edit.placeholder_text = "saqlangan" if _token() != "" else "github_pat_..."
	tok_edit.position = Vector2(20, 350) * k
	tok_edit.size = Vector2(440, 44) * k
	tok_edit.custom_minimum_size = Vector2(440, 44) * k
	tok_edit.add_theme_font_size_override("font_size", int(18.0 * k))
	panel.add_child(tok_edit)
	_mk(panel, "SAQLASH", Vector2(470, 350), Vector2(170, 44), 18, false, _save_token)
	_mk(panel, "YOPISH", Vector2(20, 402), Vector2(620, 40), 18, false, _close)
	panel.visible = false


func on_lobby() -> void:
	if g == null or btn == null:
		return
	var now := Time.get_ticks_msec()
	if now - last_check < 60000:
		return
	last_check = now
	_req(BASE_URL + "latest.json", PackedStringArray(), HTTPClient.METHOD_GET, "", _on_silent)


func _open() -> void:
	panel.visible = true
	_read_state()
	bar.visible = false
	_status("Hozirgi versiya: v%d\nTekshirilmoqda..." % cur_run)
	_req(BASE_URL + "latest.json", PackedStringArray(), HTTPClient.METHOD_GET, "", _on_check)


func _close() -> void:
	panel.visible = false
	polling = false


func _status(t: String) -> void:
	if lbl != null:
		lbl.text = t


func _req(url: String, headers: PackedStringArray, method: int, body: String, cb: Callable) -> void:
	var h := HTTPRequest.new()
	h.timeout = 12.0
	g.add_child(h)
	h.request_completed.connect(cb.bind(h))
	if h.request(url, headers, method, body) != OK:
		h.queue_free()
		_status("Tarmoq xatosi: so'rov yuborilmadi")


func _parse_remote(body: PackedByteArray) -> bool:
	var v = JSON.parse_string(body.get_string_from_utf8())
	if v is Dictionary:
		remote = v
		return true
	return false


func _is_newer() -> bool:
	if remote.is_empty():
		return false
	if int(remote.get("run", 0)) > cur_run:
		return true
	var ra := str(remote.get("assets", ""))
	return ra != "" and ra != assets_have


func _on_silent(result: int, code: int, _hd: PackedStringArray, body: PackedByteArray, h: HTTPRequest) -> void:
	h.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not _parse_remote(body):
		return
	if str(remote.get("base", "")) != base_here:
		btn.text = "APK YANGILANDI!"
		_style(btn, true)
	elif _is_newer():
		btn.text = "YANGILANISH BOR!"
		_style(btn, true)


func _show_result() -> void:
	b_get.visible = false
	b_apk.visible = false
	if str(remote.get("base", "")) != base_here:
		_status("Asosiy fayllar o'zgargan: APK ni qayta o'rnatish kerak.\nHozirgi: v%d" % cur_run)
		b_apk.visible = true
	elif _is_newer():
		_status("Yangilanish bor: v%d (hozir v%d).\n«YUKLAB OLISH» ni bosing." % [int(remote.get("run", 0)), cur_run])
		b_get.visible = true
	else:
		_status("Yangi versiya yo'q (v%d).\nDrive'da yangi fayl bo'lsa, «GITHUB'DAN SO'RASH» ni bosing." % cur_run)


func _check_manual() -> void:
	_status("Tekshirilmoqda...")
	_req(BASE_URL + "latest.json", PackedStringArray(), HTTPClient.METHOD_GET, "", _on_check)


func _on_check(result: int, code: int, _hd: PackedStringArray, body: PackedByteArray, h: HTTPRequest) -> void:
	h.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not _parse_remote(body):
		_status("Tarmoq xatosi (%d/%d). Wi-Fi'ni tekshiring va qayta urining." % [result, code])
		return
	_show_result()


func _open_apk() -> void:
	OS.shell_open(BASE_URL + "zona.apk")


func _quit() -> void:
	g.get_tree().quit()


func _save_token() -> void:
	var t := tok_edit.text.strip_edges()
	if t == "":
		_status("Token bo'sh.")
		return
	var f := FileAccess.open(TOKEN_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(t)
	tok_edit.text = ""
	tok_edit.placeholder_text = "saqlangan"
	_status("Token saqlandi. Endi «GITHUB'DAN SO'RASH» ishlaydi.")


func _gh_headers() -> PackedStringArray:
	return PackedStringArray(["Accept: application/vnd.github+json", "Authorization: Bearer " + _token(), "X-GitHub-Api-Version: 2022-11-28", "User-Agent: zona-game", "Content-Type: application/json"])


func _ask() -> void:
	if _token() == "":
		_status("Avval pastdagi maydonga GitHub token kiriting va SAQLASH bosing.")
		return
	disp_time = int(Time.get_unix_time_from_system())
	_status("GitHub'ga so'rov yuborilmoqda...")
	_req("https://api.github.com/repos/%s/actions/workflows/sync_drive.yml/dispatches" % REPO, _gh_headers(), HTTPClient.METHOD_POST, JSON.stringify({"ref": "main"}), _on_dispatch)


func _on_dispatch(result: int, code: int, _hd: PackedStringArray, _body: PackedByteArray, h: HTTPRequest) -> void:
	h.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		_status("Tarmoq xatosi (%d). Qayta urining." % result)
		return
	if code == 204:
		polling = true
		poll_left = 600.0
		_status("So'rov yuborildi. Drive tekshirilmoqda...")
		g.get_tree().create_timer(15.0).timeout.connect(_poll)
	elif code == 401 or code == 403:
		_status("Token ishlamadi (%d). Token «Actions: Read and write» ruxsatiga ega bo'lsin." % code)
	elif code == 404:
		_status("Topilmadi (404). Token shu repoga ruxsat berganmi? sync_drive.yml bormi?")
	else:
		_status("GitHub javobi: %d" % code)


func _poll() -> void:
	if not polling or not panel.visible:
		polling = false
		return
	poll_left -= 15.0
	if poll_left <= 0.0:
		polling = false
		_status("Kutish tugadi. Keyinroq «TEKSHIRISH» ni bosing.")
		return
	_req("https://api.github.com/repos/%s/actions/workflows/android.yml/runs?per_page=1" % REPO, _gh_headers(), HTTPClient.METHOD_GET, "", _on_runs)


func _on_runs(result: int, code: int, _hd: PackedStringArray, body: PackedByteArray, h: HTTPRequest) -> void:
	h.queue_free()
	var elapsed := int(Time.get_unix_time_from_system()) - disp_time
	var building := false
	var finished := false
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var v = JSON.parse_string(body.get_string_from_utf8())
		if v is Dictionary and v.get("workflow_runs") is Array and not (v["workflow_runs"] as Array).is_empty():
			var run: Dictionary = (v["workflow_runs"] as Array)[0]
			var created := int(Time.get_unix_time_from_datetime_string(str(run.get("created_at", ""))))
			if created >= disp_time - 10:
				if str(run.get("status", "")) == "completed":
					finished = str(run.get("conclusion", "")) == "success"
					if not finished:
						polling = false
						_status("Build xato bilan tugadi. GitHub Actions'ni tekshiring.")
						return
				else:
					building = true
	if finished:
		_req(BASE_URL + "latest.json", PackedStringArray(), HTTPClient.METHOD_GET, "", _on_poll_done)
		return
	if building:
		_status("Build ketmoqda (taxminan 4–6 daqiqa)...\nO'tgan vaqt: %d s" % elapsed)
	elif elapsed > 100:
		polling = false
		_status("Drive'da yangi fayl topilmadi, yangilanish yo'q.")
		return
	else:
		_status("Drive tekshirilmoqda...\nO'tgan vaqt: %d s" % elapsed)
	g.get_tree().create_timer(15.0).timeout.connect(_poll)


func _on_poll_done(result: int, code: int, _hd: PackedStringArray, body: PackedByteArray, h: HTTPRequest) -> void:
	h.queue_free()
	polling = false
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and _parse_remote(body):
		_show_result()
	else:
		_status("Build tugadi, lekin versiyani o'qib bo'lmadi. «TEKSHIRISH» ni bosing.")


func _download() -> void:
	tried = {}
	b_get.visible = false
	bar.visible = true
	bar.value = 0.0
	_next_dl()


func _next_dl() -> void:
	var rr := int(remote.get("run", 0))
	var ra := str(remote.get("assets", ""))
	if rr > cur_run and not tried.has("patch"):
		_dl("patch")
	elif ra != "" and ra != assets_have and not tried.has("assets"):
		_dl("assets")
	else:
		_finish_dl()


func _dl(kind: String) -> void:
	tried[kind] = true
	_status("Yuklanmoqda: " + kind + "...")
	dl_http = HTTPRequest.new()
	dl_http.download_file = "user://%s_dl.pck" % kind
	dl_http.timeout = 300.0
	g.add_child(dl_http)
	dl_http.request_completed.connect(_on_dl.bind(dl_http, kind))
	if dl_http.request(BASE_URL + kind + ".pck") != OK:
		dl_http.queue_free()
		dl_http = null
		_status("Yuklash boshlanmadi.")
		return
	g.get_tree().create_timer(0.4).timeout.connect(_tick.bind(dl_http))


func _tick(h) -> void:
	if h == null or not is_instance_valid(h):
		return
	var total := int(h.get_body_size())
	if total > 0:
		bar.value = 100.0 * float(h.get_downloaded_bytes()) / float(total)
	g.get_tree().create_timer(0.4).timeout.connect(_tick.bind(h))


func _on_dl(result: int, code: int, _hd: PackedStringArray, _b: PackedByteArray, h: HTTPRequest, kind: String) -> void:
	h.queue_free()
	dl_http = null
	var d := DirAccess.open("user://")
	var dl := "%s_dl.pck" % kind
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or d == null:
		if d != null:
			d.remove(dl)
		_status("Yuklanmadi (%s): %d/%d. Qayta urining." % [kind, result, code])
		return
	if kind == "patch":
		var run := int(remote.get("run", 0))
		var pf := "patch_%d.pck" % run
		if d.file_exists(pf):
			d.remove(pf)
		d.rename(dl, pf)
		_write_json(PATCH_INFO, {"run": run, "base": base_here, "file": pf})
		cur_run = run
	else:
		var hh := str(remote.get("assets", ""))
		var af := "assets_%s.pck" % hh
		if d.file_exists(af):
			d.remove(af)
		d.rename(dl, af)
		_write_json(ASSET_INFO, {"hash": hh, "file": af})
		assets_have = hh
	_next_dl()


func _finish_dl() -> void:
	bar.value = 100.0
	_status("Yangilanish yuklandi (v%d).\nIlovani yoping va qayta oching." % cur_run)
	b_quit.visible = true
