extends Node3D
## Kunci emas di Lab Komputer. Taruh scene lab_key.tscn di mana saja (mis. di atas meja / di dalam laci).
## Tekan E saat dekat untuk mengambil. Menandai "punya kunci" ke:
##   1) autoload Global (jika ada properti bernama key_flag), dan
##   2) metadata root tree (selalu) -> dibaca oleh lab_exit_door.gd.

signal picked_up

const U := preload("res://ending/scripts/build_util.gd")

@export var key_flag: String = "has_key"
@export var spin_speed: float = 1.6
@export var bob_height: float = 0.08
@export var pickup_radius: float = 1.6

var _near := false
var _taken := false
var _t := 0.0
var _visual: Node3D
var _prompt: Label
var _msg: Label


func _ready() -> void:
	U.ensure_action("interact", KEY_E)
	_build_visual()
	_build_area()
	_prompt = U.make_label(self, 110)
	_prompt.text = "[E] Ambil kunci"
	_msg = U.make_label(self, 170)
	# catat waktu mulai (untuk statistik di layar ending)
	var root := get_tree().root
	if not root.has_meta("escape_start_msec"):
		root.set_meta("escape_start_msec", Time.get_ticks_msec())


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var gold := U.mat(Color(1.0, 0.82, 0.25), "", 0.0, 0.25, 0.9, Color(1.0, 0.7, 0.1), 0.35)
	# kepala (cincin) : torus
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.045
	tm.outer_radius = 0.095
	ring.mesh = tm
	ring.material_override = gold
	ring.rotation_degrees.x = 90.0
	ring.position = Vector3(0, 0.16, 0)
	_visual.add_child(ring)
	# batang + gigi
	U.box(_visual, Vector3(0.04, 0.30, 0.025), Vector3(0, -0.04, 0), gold)
	U.box(_visual, Vector3(0.09, 0.035, 0.025), Vector3(0.055, -0.14, 0), gold)
	U.box(_visual, Vector3(0.07, 0.035, 0.025), Vector3(0.045, -0.07, 0), gold)
	_visual.position.y = 0.25
	U.glow_sprite(_visual, 0.9, Vector3.ZERO, Color(1.0, 0.85, 0.4, 0.55))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.85, 0.5)
	l.light_energy = 0.8
	l.omni_range = 2.5
	_visual.add_child(l)


func _build_area() -> void:
	var a := Area3D.new()
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = pickup_radius
	cs.shape = s
	a.add_child(cs)
	add_child(a)
	a.body_entered.connect(_on_enter)
	a.body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if body is CharacterBody3D and not _taken:
		_near = true
		_prompt.visible = true


func _on_exit(body: Node3D) -> void:
	if body is CharacterBody3D:
		_near = false
		_prompt.visible = false


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	_visual.rotation.y += spin_speed * delta
	_visual.position.y = 0.25 + sin(_t * 2.0) * bob_height


func _unhandled_input(event: InputEvent) -> void:
	if _near and not _taken and event.is_action_pressed("interact"):
		_pick_up()


func _pick_up() -> void:
	_taken = true
	_prompt.visible = false
	_visual.visible = false
	U.play(self, "pickup.wav", -2.0)
	var g := get_node_or_null("/root/Global")
	if g != null and g.get(key_flag) != null:
		g.set(key_flag, true)
	get_tree().root.set_meta(key_flag, true)
	picked_up.emit()
	U.show_msg(self, _msg, "Kamu mendapat KUNCI! Cari pintu keluar lab.", 3.0)
	await get_tree().create_timer(3.2).timeout
	queue_free()
