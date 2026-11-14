extends Node

const BASE := "https://github.com/lutfullossr-creator/godot-4-3d-third-person-controller/releases/download/latest/"
const PCK := "user://update.pck"
const TMP := "user://update_tmp.pck"
const VER := "user://update_version.txt"
const GAME := "res://ultimatum.tscn"

var http: HTTPRequest
var lbl: Label
var bar: ProgressBar
var phase := 0
var remote_ver := ""
var started := false


func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	var ui := CanvasLayer.new()
	add_child(ui)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	ui.add_child(box)
	lbl = Label.new()
	lbl.text = "Yangilanish tekshirilmoqda..."
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)
	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(600, 30)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.visible = false
	box.add_child(bar)
	http = HTTPRequest.new()
	http.timeout = 10.0
	add_child(http)
	http.request_completed.connect(_on_done)
	if http.request(BASE + "version.txt") != OK:
		_start_game()


func _local_ver() -> String:
	if FileAccess.file_exists(VER):
		return FileAccess.get_file_as_string(VER).strip_edges()
	return ""


func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_start_game()
		return
	if phase == 0:
		remote_ver = body.get_string_from_utf8().strip_edges()
		if remote_ver == "" or (remote_ver == _local_ver() and FileAccess.file_exists(PCK)):
			_start_game()
			return
		phase = 1
		lbl.text = "Yangilanish yuklanmoqda..."
		bar.visible = true
		http.download_file = TMP
		http.timeout = 0.0
		if http.request(BASE + "game.pck") != OK:
			_start_game()
	else:
		if FileAccess.file_exists(PCK):
			DirAccess.remove_absolute(PCK)
		DirAccess.rename_absolute(TMP, PCK)
		var f := FileAccess.open(VER, FileAccess.WRITE)
		if f != null:
			f.store_string(remote_ver)
			f.close()
		_start_game()


func _process(_d: float) -> void:
	if phase == 1 and not started:
		var total := http.get_body_size()
		if total > 0:
			bar.value = 100.0 * http.get_downloaded_bytes() / total


func _start_game() -> void:
	if started:
		return
	started = true
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(TMP)
	if FileAccess.file_exists(PCK):
		ProjectSettings.load_resource_pack(PCK)
	get_tree().change_scene_to_file.call_deferred(GAME)
