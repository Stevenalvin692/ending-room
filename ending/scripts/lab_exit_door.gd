extends Node3D
## Pintu keluar Lab Komputer -> menuju Ruang Ending.
## Pasang lab_exit_door.tscn pada lubang pintu di map_komputer. Sisi depan pintu = arah +Z lokal
## (putar node dengan rotation Y supaya menghadap ke dalam lab).
##
## Alur: dekat pintu -> [E] -> (terkunci? pesan) / (punya kunci? buka) -> melangkah lewat pintu -> fade putih -> ending_room.tscn

signal unlocked
signal opened

const U := preload("res://ending/scripts/build_util.gd")

@export_file("*.tscn") var ending_scene: String = "res://ending/scenes/ending_room.tscn"
@export var requires_key: bool = true
## Nama variabel kunci. Dicek di metadata root & autoload Global (properti dengan nama ini).
@export var key_flag: String = "has_key"
## Untuk testing: pintu langsung bisa dibuka tanpa kunci.
@export var debug_always_open: bool = false
@export var door_width: float = 1.1
@export var door_height: float = 2.2

var _near := false
var _busy := false
var _is_open := false
var _going := false
var _unlocked_externally := false
var _pivot: Node3D
var _panel_body: StaticBody3D
var _light: OmniLight3D
var _led: MeshInstance3D
var _prompt: Label
var _msg: Label
var _fade: ColorRect


func _ready() -> void:
	U.ensure_action("interact", KEY_E)
	_build_door()
	_build_areas()
	_prompt = U.make_label(self, 110)
	_prompt.text = "[E] Buka pintu"
	_msg = U.make_label(self, 170)
	_fade = U.make_fade(self, Color.WHITE, 0.0)
	var root := get_tree().root
	if not root.has_meta("escape_start_msec"):
		root.set_meta("escape_start_msec", Time.get_ticks_msec())


## Dipanggil dari script lain (mis. key.gd lama) untuk membuka kunci pintu.
func unlock() -> void:
	_unlocked_externally = true


func _has_key() -> bool:
	if debug_always_open or not requires_key or _unlocked_externally:
		return true
	var root := get_tree().root
	if root.has_meta(key_flag) and bool(root.get_meta(key_flag)):
		return true
	var g := get_node_or_null("/root/Global")
	if g != null:
		var v = g.get(key_flag)
		if v != null:
			return bool(v)
	return false


# ---------------------------------------------------------------- bangun visual
func _build_door() -> void:
	var w := door_width
	var h := door_height
	var frame_mat := U.mat(Color(0.32, 0.2, 0.1), "door_wood.png", 0.0, 0.7)
	U.box(self, Vector3(0.14, h + 0.14, 0.22), Vector3(-(w / 2.0 + 0.07), (h + 0.14) / 2.0, 0), frame_mat, true)
	U.box(self, Vector3(0.14, h + 0.14, 0.22), Vector3((w / 2.0 + 0.07), (h + 0.14) / 2.0, 0), frame_mat, true)
	U.box(self, Vector3(w + 0.28, 0.14, 0.22), Vector3(0, h + 0.07, 0), frame_mat, true)

	# engsel di sisi kiri
	_pivot = Node3D.new()
	_pivot.position = Vector3(-w / 2.0, 0, 0)
	add_child(_pivot)
	var panel := U.box(_pivot, Vector3(w, h, 0.06), Vector3(w / 2.0, h / 2.0, 0),
			U.mat(Color.WHITE, "door_wood.png", 0.0, 0.6), true)
	_panel_body = panel.get_child(0) as StaticBody3D
	U.sphere(_pivot, 0.05, Vector3(w - 0.12, h * 0.48, 0.07), U.mat(Color(0.85, 0.75, 0.35), "", 0.0, 0.25, 0.9))
	U.sphere(_pivot, 0.05, Vector3(w - 0.12, h * 0.48, -0.07), U.mat(Color(0.85, 0.75, 0.35), "", 0.0, 0.25, 0.9))

	# papan KELUAR di atas pintu
	U.quad(self, Vector2(0.7, 0.35), Vector3(0, h + 0.4, 0.12),
			U.mat(Color.WHITE, "exit_sign.png", 0.0, 0.5, 0.0, Color.BLACK, 0.0, true, true))

	# keypad + LED status di samping pintu
	U.box(self, Vector3(0.14, 0.22, 0.04), Vector3(w / 2.0 + 0.32, 1.25, 0.1), U.mat(Color(0.12, 0.13, 0.16), "", 0.0, 0.4, 0.5))
	_led = U.sphere(self, 0.025, Vector3(w / 2.0 + 0.32, 1.3, 0.13), U.mat(Color.RED, "", 0.0, 0.3, 0.0, Color.RED, 3.0))

	# lampu status (merah = terkunci, hijau = terbuka)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.2, 0.15)
	_light.light_energy = 0.6
	_light.omni_range = 3.0
	_light.position = Vector3(0, h + 0.3, 0.5)
	add_child(_light)

	# cahaya terang di balik pintu (terlihat saat pintu terbuka)
	U.quad(self, Vector2(w + 0.4, h + 0.4), Vector3(0, h / 2.0, -0.95),
			U.mat(Color.WHITE, "gate_light.png", 0.0, 1.0, 0.0, Color.BLACK, 0.0, true, true))


func _build_areas() -> void:
	# area interaksi di depan pintu
	var a := Area3D.new()
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(door_width + 2.0, door_height, 2.8)
	cs.shape = s
	cs.position = Vector3(0, door_height / 2.0, 1.4)
	a.add_child(cs)
	add_child(a)
	a.body_entered.connect(_on_near_enter)
	a.body_exited.connect(_on_near_exit)
	# ambang pintu: melangkah ke sini setelah terbuka -> pindah ke ending
	var th := Area3D.new()
	var tcs := CollisionShape3D.new()
	var ts := BoxShape3D.new()
	ts.size = Vector3(door_width, door_height, 0.8)
	tcs.shape = ts
	tcs.position = Vector3(0, door_height / 2.0, -0.7)
	th.add_child(tcs)
	add_child(th)
	th.body_entered.connect(_on_threshold)


func _on_near_enter(body: Node3D) -> void:
	if body is CharacterBody3D and not _is_open:
		_near = true
		_prompt.visible = true


func _on_near_exit(body: Node3D) -> void:
	if body is CharacterBody3D:
		_near = false
		_prompt.visible = false


# ---------------------------------------------------------------- interaksi
func _unhandled_input(event: InputEvent) -> void:
	if _near and event.is_action_pressed("interact"):
		_try_open()


func _try_open() -> void:
	if _busy or _is_open:
		return
	if not _has_key():
		U.play(self, "locked.wav", -3.0)
		U.show_msg(self, _msg, "Pintu terkunci. Cari kunci di lab komputer!", 2.6)
		_flash_red()
		return
	_busy = true
	_prompt.visible = false
	_open_sequence()


func _flash_red() -> void:
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", 2.5, 0.08)
	tw.tween_property(_light, "light_energy", 0.6, 0.25)


func _open_sequence() -> void:
	unlocked.emit()
	_light.light_color = Color(0.2, 1.0, 0.35)
	(_led.material_override as StandardMaterial3D).albedo_color = Color.GREEN
	(_led.material_override as StandardMaterial3D).emission = Color.GREEN
	U.play(self, "door_unlock.wav", -2.0)
	U.show_msg(self, _msg, "Pintu terbuka! Melangkahlah keluar...", 3.0)
	await get_tree().create_timer(0.7).timeout
	U.play(self, "door_open.wav", -2.0)
	_panel_body.collision_layer = 0
	var tw := create_tween()
	tw.tween_property(_pivot, "rotation_degrees:y", -105.0, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_is_open = true
	opened.emit()


func _on_threshold(body: Node3D) -> void:
	if _going or not _is_open or not (body is CharacterBody3D):
		return
	_going = true
	U.play(self, "fanfare.wav", -6.0)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 1.0)
	await tw.finished
	if ResourceLoader.exists(ending_scene):
		get_tree().change_scene_to_file(ending_scene)
	else:
		push_error("Scene ending tidak ditemukan: " + ending_scene)
