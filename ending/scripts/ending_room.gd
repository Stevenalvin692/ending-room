extends Node3D
## RUANG ENDING: "Aula Kelulusan".
## Seluruh ruangan dibangun lewat kode dari tekstur/audio di res://ending/assets, jadi cukup
## buka scene ending_room.tscn dan jalankan (F6). Model Kenney di proyek dipakai sebagai dekorasi bila ada.
##
## Alur: pemain muncul di pintu lab (belakang) -> berjalan di karpet merah -> melewati
## podium sertifikat & piala -> masuk ke cahaya di gerbang -> layar ENDING (statistik + kredit + tombol).

const U := preload("res://ending/scripts/build_util.gd")
const EndingPlayer := preload("res://ending/scripts/ending_player.gd")
const EndingUI := preload("res://ending/scripts/ending_ui.gd")
const KENNEY := "res://kenney_furniture-kit/Models/GLTF format/"

## Scene tujuan tombol "Main Lagi".
@export_file("*.tscn") var lab_scene: String = "res://map_komputer.tscn"
## Skala dekorasi Kenney (ubah jika terlihat terlalu kecil/besar).
@export var decor_scale: float = 1.5

const W := 12.0   # lebar (x)
const L := 26.0   # panjang (z)
const H := 5.0    # tinggi

var _player: CharacterBody3D
var _fade: ColorRect
var _hint: Label
var _trophy: Node3D
var _done := false


func _ready() -> void:
	_build_environment()
	_build_shell()
	_build_carpet_and_pillars()
	_build_podium()
	_build_decor()
	_build_lights()
	_build_confetti()
	_build_gate()
	_spawn_player()
	_start_audio()
	_intro()


func _process(delta: float) -> void:
	if _trophy != null:
		_trophy.rotation.y += delta * 0.9


# ------------------------------------------------------------------ lingkungan
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.95, 0.85)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


# ------------------------------------------------------------------ dinding, lantai, atap
func _build_shell() -> void:
	var floor_m := U.mat(Color.WHITE, "floor_tile.png", 0.5, 0.35)
	var wall_m := U.mat(Color.WHITE, "wall_paint.png", 0.25, 0.9)
	var ceil_m := U.mat(Color(0.95, 0.93, 0.88), "", 0.0, 0.9)
	U.box(self, Vector3(W, 0.2, L), Vector3(0, -0.1, 0), floor_m, true)
	U.box(self, Vector3(W, 0.2, L), Vector3(0, H + 0.1, 0), ceil_m, true)
	# dinding kiri / kanan
	U.box(self, Vector3(0.2, H, L + 0.4), Vector3(-W / 2.0 - 0.1, H / 2.0, 0), wall_m, true)
	U.box(self, Vector3(0.2, H, L + 0.4), Vector3(W / 2.0 + 0.1, H / 2.0, 0), wall_m, true)

	# dinding depan (belakang pemain) + pintu lab yang sudah tertutup
	U.box(self, Vector3(W + 0.4, H, 0.2), Vector3(0, H / 2.0, L / 2.0 + 0.1), wall_m, true)
	var wood := U.mat(Color.WHITE, "door_wood.png", 0.0, 0.6)
	U.box(self, Vector3(1.1, 2.2, 0.08), Vector3(0, 1.1, L / 2.0 - 0.04), wood)
	U.box(self, Vector3(1.34, 0.14, 0.14), Vector3(0, 2.27, L / 2.0 - 0.07), wood)
	U.box(self, Vector3(0.14, 2.34, 0.14), Vector3(-0.62, 1.17, L / 2.0 - 0.07), wood)
	U.box(self, Vector3(0.14, 2.34, 0.14), Vector3(0.62, 1.17, L / 2.0 - 0.07), wood)
	U.quad(self, Vector2(1.3, 0.49), Vector3(0, 2.75, L / 2.0 - 0.02),
			U.mat(Color.WHITE, "sign_lab.png", 0.0, 0.6), Vector3(0, 180, 0))

	# dinding belakang dengan lubang gerbang (lebar 3, tinggi 3.4)
	var bz := -L / 2.0 - 0.1
	U.box(self, Vector3(4.7, H, 0.2), Vector3(-3.85, H / 2.0, bz), wall_m, true)
	U.box(self, Vector3(4.7, H, 0.2), Vector3(3.85, H / 2.0, bz), wall_m, true)
	U.box(self, Vector3(3.0, H - 3.4, 0.2), Vector3(0, 3.4 + (H - 3.4) / 2.0, bz), wall_m, true)
	# banner SELAMAT di atas gerbang
	U.quad(self, Vector2(8.0, 1.6), Vector3(0, 4.2, -L / 2.0 + 0.015),
			U.mat(Color.WHITE, "banner_selamat.png", 0.0, 0.6, 0.0, Color.BLACK, 0.0, false, true))
	# papan KELUAR di dinding kiri/kanan
	var exit_m := U.mat(Color.WHITE, "exit_sign.png", 0.0, 0.5, 0.0, Color.BLACK, 0.0, true, true)
	U.quad(self, Vector2(1.0, 0.5), Vector3(-W / 2.0 + 0.02, 3.0, -9.5), exit_m, Vector3(0, 90, 0))
	U.quad(self, Vector2(1.0, 0.5), Vector3(W / 2.0 - 0.02, 3.0, -9.5), exit_m, Vector3(0, -90, 0))


func _build_carpet_and_pillars() -> void:
	U.box(self, Vector3(2.2, 0.03, L - 1.6), Vector3(0, 0.015, 0), U.mat(Color.WHITE, "carpet.png", 0.0, 0.95))
	var marble := U.mat(Color(0.95, 0.94, 0.9), "", 0.0, 0.3)
	var gold := U.mat(Color(1.0, 0.82, 0.3), "", 0.0, 0.3, 0.9)
	for z in [-9.0, -3.0, 3.0, 9.0]:
		for sx in [-1.0, 1.0]:
			var x: float = 4.6 * sx
			U.cylinder(self, 0.38, 0.4, H, Vector3(x, H / 2.0, z), marble, true)
			U.box(self, Vector3(1.0, 0.18, 1.0), Vector3(x, 0.09, z), gold)
			U.box(self, Vector3(1.0, 0.18, 1.0), Vector3(x, H - 0.09, z), gold)
	# rumbai bendera warna-warni di antara pilar
	var cols := [Color(0.95, 0.3, 0.3), Color(0.98, 0.8, 0.25), Color(0.3, 0.7, 0.95), Color(0.4, 0.85, 0.5), Color(0.85, 0.45, 0.9)]
	for z in [-9.0, -3.0, 3.0, 9.0]:
		for i in range(15):
			var x2 := -5.6 + i * 0.8
			var sag := 0.35 * (1.0 - pow((x2 / 5.6), 2.0))
			U.box(self, Vector3(0.28, 0.28, 0.02), Vector3(x2, 4.55 - sag, z),
					U.mat(cols[i % cols.size()], "", 0.0, 0.8), false, Vector3(0, 0, 45))


# ------------------------------------------------------------------ podium, sertifikat, piala
func _build_podium() -> void:
	var wood := U.mat(Color(0.8, 0.6, 0.4), "door_wood.png", 0.0, 0.55)
	# mimbar + sertifikat (kanan karpet)
	U.box(self, Vector3(0.9, 1.1, 0.6), Vector3(2.6, 0.55, -6.0), wood, true)
	U.quad(self, Vector2(0.75, 0.5), Vector3(2.6, 1.16, -5.99),
			U.mat(Color.WHITE, "certificate.png", 0.0, 0.6), Vector3(-65, 0, 0))
	# alas piala (kiri karpet)
	U.box(self, Vector3(0.6, 1.0, 0.6), Vector3(-2.6, 0.5, -6.0), U.mat(Color(0.96, 0.96, 0.95), "", 0.0, 0.25), true)
	_trophy = Node3D.new()
	_trophy.position = Vector3(-2.6, 1.0, -6.0)
	add_child(_trophy)
	var gold := U.mat(Color(1.0, 0.8, 0.25), "", 0.0, 0.2, 1.0, Color(1.0, 0.65, 0.1), 0.25)
	U.cylinder(_trophy, 0.2, 0.22, 0.08, Vector3(0, 0.04, 0), gold)
	U.cylinder(_trophy, 0.04, 0.06, 0.28, Vector3(0, 0.22, 0), gold)
	U.cylinder(_trophy, 0.22, 0.07, 0.36, Vector3(0, 0.53, 0), gold)
	for sx in [-1.0, 1.0]:
		var h := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.045
		tm.outer_radius = 0.09
		h.mesh = tm
		h.material_override = gold
		h.position = Vector3(0.26 * sx, 0.55, 0)
		h.rotation_degrees.x = 90.0
		_trophy.add_child(h)
	U.glow_sprite(_trophy, 1.4, Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.45, 0.6))
	# papan petunjuk di lantai dekat mimbar tidak diperlukan; spotlight di _build_lights


# ------------------------------------------------------------------ dekorasi dari aset Kenney (opsional)
func _build_decor() -> void:
	var s := decor_scale
	for sx in [-1.0, 1.0]:
		U.try_model(self, KENNEY + "pottedPlant.glb", Vector3(5.3 * sx, 0, 11.7), 0.0, s)
		U.try_model(self, KENNEY + "pottedPlant.glb", Vector3(5.3 * sx, 0, -11.7), 0.0, s)
		U.try_model(self, KENNEY + "bench.glb", Vector3(5.4 * sx, 0, 0.0), 90.0 * sx, s)
		U.try_model(self, KENNEY + "bench.glb", Vector3(5.4 * sx, 0, -6.0), 90.0 * sx, s)
		U.try_model(self, KENNEY + "lampRoundFloor.glb", Vector3(5.4 * sx, 0, 6.0), 0.0, s)
		U.try_model(self, KENNEY + "lampRoundFloor.glb", Vector3(5.4 * sx, 0, -9.5), 0.0, s)


# ------------------------------------------------------------------ cahaya
func _build_lights() -> void:
	var lamp_m := U.mat(Color(1.0, 0.95, 0.8), "", 0.0, 0.3, 0.0, Color(1.0, 0.9, 0.6), 2.0)
	for z in [9.0, 4.5, 0.0, -4.5, -9.0]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.93, 0.78)
		l.light_energy = 1.1
		l.omni_range = 9.0
		l.position = Vector3(0, H - 0.7, z)
		add_child(l)
		U.sphere(self, 0.2, Vector3(0, H - 0.5, z), lamp_m)
	# sorot ke mimbar dan piala
	for x in [2.6, -2.6]:
		var sp := SpotLight3D.new()
		sp.light_color = Color(1.0, 0.92, 0.75)
		sp.light_energy = 6.0
		sp.spot_range = 7.0
		sp.spot_angle = 24.0
		sp.shadow_enabled = true
		sp.position = Vector3(x, H - 0.3, -6.0)
		sp.rotation_degrees = Vector3(-90, 0, 0)
		add_child(sp)


func _build_confetti() -> void:
	var p := CPUParticles3D.new()
	p.position = Vector3(0, H - 0.3, -3.0)
	p.amount = 260
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(5.0, 0.1, 10.0)
	p.direction = Vector3(0, -1, 0)
	p.spread = 25.0
	p.gravity = Vector3(0, -1.4, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 1.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	g.colors = PackedColorArray([Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.75, 1), Color(0.45, 0.9, 0.5), Color(0.9, 0.5, 1)])
	p.color_initial_ramp = g
	var qm := QuadMesh.new()
	qm.size = Vector2(0.12, 0.08)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	qm.material = m
	p.mesh = qm
	add_child(p)


# ------------------------------------------------------------------ gerbang cahaya = pemicu ending
func _build_gate() -> void:
	var gz := -L / 2.0
	U.quad(self, Vector2(3.0, 3.4), Vector3(0, 1.7, gz - 0.4),
			U.mat(Color.WHITE, "gate_light.png", 0.0, 1.0, 0.0, Color.BLACK, 0.0, true, true))
	# penghalang tak terlihat di belakang gerbang
	var blocker := StaticBody3D.new()
	var bcs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(3.4, 3.6, 0.2)
	bcs.shape = bs
	blocker.add_child(bcs)
	blocker.position = Vector3(0, 1.8, gz - 0.55)
	add_child(blocker)
	U.glow_sprite(self, 6.0, Vector3(0, 1.8, gz + 0.6), Color(1.0, 0.95, 0.75, 0.7))
	# bias cahaya jatuh di lantai
	var spill := StandardMaterial3D.new()
	spill.albedo_texture = U.tex("glow.png")
	spill.albedo_color = Color(1.0, 0.95, 0.7, 0.8)
	spill.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spill.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spill.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spill.cull_mode = BaseMaterial3D.CULL_DISABLED
	U.quad(self, Vector2(4.5, 5.5), Vector3(0, 0.05, gz + 2.0), spill, Vector3(-90, 0, 0))
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.95, 0.8)
	gl.light_energy = 2.5
	gl.omni_range = 10.0
	gl.position = Vector3(0, 2.0, gz + 1.0)
	add_child(gl)
	# pemicu
	var a := Area3D.new()
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(3.0, 3.4, 1.6)
	cs.shape = s
	cs.position = Vector3(0, 1.7, gz + 0.4)
	a.add_child(cs)
	add_child(a)
	a.body_entered.connect(_on_gate)


# ------------------------------------------------------------------ pemain, audio, intro
func _spawn_player() -> void:
	_player = CharacterBody3D.new()
	_player.set_script(EndingPlayer)
	_player.position = Vector3(0, 0.05, L / 2.0 - 2.0)
	add_child(_player)


func _start_audio() -> void:
	U.play(self, "ending_music.wav", -9.0, true)
	U.play(self, "hall_ambient.wav", -22.0, true)


func _intro() -> void:
	_fade = U.make_fade(self, Color.WHITE, 1.0)
	_hint = U.make_label(self, 70)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 1.8)
	U.show_msg(self, _hint, "Aula Kelulusan - berjalanlah di karpet merah menuju cahaya di ujung aula", 7.0)


func _elapsed_seconds() -> float:
	var root := get_tree().root
	if root.has_meta("escape_start_msec"):
		return (Time.get_ticks_msec() - int(root.get_meta("escape_start_msec"))) / 1000.0
	return -1.0


func _on_gate(body: Node3D) -> void:
	if _done or not (body is CharacterBody3D):
		return
	_done = true
	body.set("frozen", true)
	U.play(self, "fanfare.wav", -3.0)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 1.2)
	await tw.finished
	var ui := CanvasLayer.new()
	ui.set_script(EndingUI)
	ui.set("lab_scene", lab_scene)
	add_child(ui)
	ui.call("show_ending", _elapsed_seconds())
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 1.2)
