extends RefCounted
# PLAGIN: BR LOOT rejimi (qurol, dori, granata yerdan olinadi, bitta hayot).
# Egasi: 1-akkaunt. Faqat shu faylni oʻzgartiring.

const WeaponDB = preload("res://freefire/weapons.gd")
var g
var loot: Array = []
var root: Node3D = null
var spin := 0.0


func setup(game) -> void:
	g = game


func on_lobby() -> void:
	_clear()


func on_match_start(_n: int) -> void:
	_clear()
	if g.sel_map == 2:
		g.rules["win_to"] = 1
		g.rules["rounds"] = 1


func on_round_start(_ri: int) -> bool:
	if g.sel_map != 2:
		return false
	for f in g.fighters:
		f.give(11)
		var s: Dictionary = g.inv(f)
		s["gren"] = 0
		s["med"] = 0
	g.round_t = 300.0
	g.round_len = 300.0
	_spawn()
	g._go_live("BR: qurol toping!")
	return true


func on_update(delta: float) -> void:
	if g.sel_map != 2:
		return
	spin += delta
	for it in loot:
		if is_instance_valid(it["node"]):
			it["node"].rotation.y = spin * 1.5
	for f in g.fighters:
		if not f.alive:
			continue
		for i in range(loot.size() - 1, -1, -1):
			var it: Dictionary = loot[i]
			if not is_instance_valid(it["node"]):
				loot.remove_at(i)
				continue
			var d: float = Vector2(f.global_position.x - it["pos"].x, f.global_position.z - it["pos"].z).length()
			if d < 1.8 and _take(f, it):
				it["node"].queue_free()
				loot.remove_at(i)
	var a := [0, 0]
	for f in g.fighters:
		if f.alive:
			a[f.team] += 1
	g.rules["top"] = "BR   Tirik: %d : %d     Zona %d m     %d s" % [a[0], a[1], int(g.zone_r), int(ceil(maxf(g.round_t, 0.0)))]


func on_think(b, delta: float) -> bool:
	if g.sel_map != 2 or loot.is_empty():
		return false
	var want := ""
	if str(WeaponDB.W[b.slot_wid[0]]["s"]) == "pistol":
		want = "w"
	elif b.hp < 120 and int(g.inv(b)["med"]) == 0:
		want = "m"
	if want == "":
		return false
	var t = g._nearest_enemy(b)
	if t != null and (t.global_position - b.global_position).length() < 30.0:
		return false
	var best = null
	var bd := 90.0
	for it in loot:
		if it["type"] != want or not is_instance_valid(it["node"]):
			continue
		var d: float = Vector2(b.global_position.x - it["pos"].x, b.global_position.z - it["pos"].z).length()
		if d < bd:
			bd = d
			best = it
	if best == null:
		return false
	var to: Vector3 = best["pos"] - b.global_position
	b.yaw = lerp_angle(b.yaw, atan2(-to.x, -to.z), clampf(4.0 * delta, 0.0, 1.0))
	b.move_input = Vector2(0, -1)
	b.sprint = true
	b.want_fire = false
	g._unstick(b, delta)
	return true


func _take(f, it: Dictionary) -> bool:
	var s: Dictionary = g.inv(f)
	var t: String = it["type"]
	if t == "w":
		equip(f, int(it["w"]))
		if f == g.player:
			g._msg("Oldingiz: %s" % WeaponDB.W[int(it["w"])]["n"], 1.5)
		return true
	if t == "m":
		if int(s["med"]) >= 5:
			return false
		s["med"] = int(s["med"]) + 1
	elif t == "g":
		if int(s["gren"]) >= 4:
			return false
		s["gren"] = int(s["gren"]) + 1
	elif t == "a":
		f.slot_res[f.slot] = int(f.slot_res[f.slot]) + int(WeaponDB.W[f.wid]["mag"]) * 2
	if f == g.player:
		g._msg({"m": "Dori +1", "g": "Granata +1", "a": "Oʻqlar +2 magazin"}.get(t, ""), 1.2)
	return true


func equip(f, w_i: int) -> void:
	var w: Dictionary = WeaponDB.W[w_i]
	var si := 1 if str(w["s"]) == "pistol" else 0
	f.slot_wid[si] = w_i
	f.slot_mag[si] = int(w["mag"])
	f.slot_res[si] = int(w["mag"]) * 3
	if si == 0 and f.slot != 0:
		f.slot_mag[f.slot] = f.mag
		f.slot = 0
	if f.slot == si:
		f.rl = 0.0
		f.wid = w_i
		f.mag = f.slot_mag[si]


func _clear() -> void:
	if root != null and is_instance_valid(root):
		root.queue_free()
	root = null
	loot = []


func _spawn() -> void:
	_clear()
	root = Node3D.new()
	g.add_child(root)
	var my_root := root
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	if not is_instance_valid(my_root) or my_root != root:
		return
	var space = g.get_world_3d().direct_space_state
	var made := 0
	var tries := 0
	while made < 70 and tries < 900:
		tries += 1
		var x := randf_range(-150.0, 150.0)
		var z := randf_range(-150.0, 150.0)
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 40.0, z), Vector3(x, -3.0, z), 1)
		var h: Dictionary = space.intersect_ray(q)
		if h.is_empty():
			continue
		var p: Vector3 = h["position"]
		if p.y > 0.8:
			continue
		var r := randf()
		var kind := "w"
		if r > 0.5:
			kind = "m"
		if r > 0.68:
			kind = "g"
		if r > 0.82:
			kind = "a"
		_make(p + Vector3(0, 0.45, 0), kind)
		made += 1


func _make(pos: Vector3, kind: String) -> void:
	var wi := -1
	var label := "DORI"
	var col := Color(0.3, 1.0, 0.45)
	if kind == "w":
		wi = randi() % WeaponDB.W.size()
		while str(WeaponDB.W[wi]["s"]) == "pistol":
			wi = randi() % WeaponDB.W.size()
		label = str(WeaponDB.W[wi]["n"])
		col = Color(1.0, 0.8, 0.2)
	elif kind == "g":
		label = "GRANATA"
		col = Color(1.0, 0.5, 0.15)
	elif kind == "a":
		label = "OʻQLAR"
		col = Color(0.4, 0.8, 1.0)
	var n := Node3D.new()
	root.add_child(n)
	n.global_position = pos
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.35, 0.5)
	box.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	box.material_override = m
	n.add_child(box)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.12
	cm.height = 9.0
	beam.mesh = cm
	beam.position = Vector3(0, 4.5, 0)
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(col.r, col.g, col.b, 0.28)
	beam.material_override = bmat
	n.add_child(beam)
	var lb := Label3D.new()
	lb.text = label
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.position = Vector3(0, 0.9, 0)
	lb.pixel_size = 0.012
	lb.font_size = 40
	lb.modulate = col
	lb.visibility_range_end = 35.0
	n.add_child(lb)
	loot.append({"node": n, "type": kind, "w": wi, "pos": pos})
