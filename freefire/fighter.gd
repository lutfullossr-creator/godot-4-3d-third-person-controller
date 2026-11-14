extends CharacterBody3D

const WeaponDB = preload("res://freefire/weapons.gd")
const SPEED := [5.0, 2.4, 1.0]
const BODY_H := [1.4, 0.9, 0.7]
const HEAD_Y := [1.6, 1.1, 0.62]

signal hit_info(attacker, target, dmg, head)
signal died(f)

var team := 0
var is_bot := true
var hp := 200
var wid := 0
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
var body_col: CollisionShape3D
var head_col: CollisionShape3D
var head_area: Area3D
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var gun_mesh: MeshInstance3D


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
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
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.4
	body_mesh = MeshInstance3D.new()
	body_mesh.mesh = cm
	body_mesh.material_override = _mat(col)
	add_child(body_mesh)
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
	add_child(head_mesh)
	var gm := BoxMesh.new()
	gm.size = Vector3(0.08, 0.1, 0.7)
	gun_mesh = MeshInstance3D.new()
	gun_mesh.mesh = gm
	gun_mesh.material_override = _mat(Color(0.1, 0.1, 0.1))
	add_child(gun_mesh)
	apply_stance()


func head_y() -> float:
	return HEAD_Y[stance]


func eye() -> Vector3:
	return global_position + Vector3(0.0, HEAD_Y[stance], 0.0)


func apply_stance() -> void:
	var h: float = BODY_H[stance]
	(body_col.shape as CapsuleShape3D).height = h
	body_col.position.y = h * 0.5
	(body_mesh.mesh as CapsuleMesh).height = h
	body_mesh.position.y = h * 0.5
	head_area.position.y = HEAD_Y[stance]
	head_mesh.position.y = HEAD_Y[stance]
	gun_mesh.position = Vector3(0.3, HEAD_Y[stance] - 0.35, -0.45)


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
	move_input = Vector2.ZERO
	want_fire = false
	want_jump = false
	body_col.disabled = false
	head_col.disabled = false
	apply_stance()


func reload() -> void:
	if rl <= 0.0 and mag < WeaponDB.W[wid]["mag"]:
		rl = WeaponDB.W[wid]["rl"]


func hurt(dmg: int, by, head: bool) -> void:
	if not alive:
		return
	hp -= dmg
	hit_info.emit(by, self, dmg, head)
	if hp <= 0:
		hp = 0
		alive = false
		visible = false
		body_col.set_deferred("disabled", true)
		head_col.set_deferred("disabled", true)
		died.emit(self)


func try_fire() -> void:
	if cd > 0.0 or rl > 0.0:
		return
	var w: Dictionary = WeaponDB.W[wid]
	if mag <= 0:
		reload()
		return
	mag -= 1
	cd = w["rate"] * (1.8 if is_bot else 1.0)
	var from := origin_override if use_origin else eye()
	var space := get_world_3d().direct_space_state
	for i in range(int(w["pel"])):
		var sp: float = w["spread"] * (3.0 if is_bot else 1.0)
		var d := (aim_dir + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * sp).normalized()
		var q := PhysicsRayQueryParameters3D.create(from, from + d * 120.0, 7, [get_rid(), head_area.get_rid()])
		q.collide_with_areas = true
		var r := space.intersect_ray(q)
		if r.is_empty():
			continue
		var c = r["collider"]
		var tgt = null
		var head := false
		if c is Area3D:
			tgt = c.get_parent()
			head = true
		elif c.has_method("hurt"):
			tgt = c
		if tgt != null and tgt.has_method("hurt") and tgt.alive and tgt.team != team:
			var dmg := int(float(w["dmg"]) * (2.4 if head else 1.0) * (0.5 if is_bot else 1.0))
			tgt.hurt(dmg, self, head)


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
