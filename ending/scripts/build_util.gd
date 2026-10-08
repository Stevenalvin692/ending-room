extends RefCounted
## Helper bersama untuk paket "Ending Escape School".
## Dipakai lewat: const U := preload("res://ending/scripts/build_util.gd")

const TEX_DIR := "res://ending/assets/textures/"
const SND_DIR := "res://ending/assets/audio/"


static func tex(file_name: String) -> Texture2D:
	var p := TEX_DIR + file_name
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	push_warning("Tekstur tidak ditemukan: " + p)
	return null


## Membuat material. tri > 0 = tekstur ditiling per-meter di dunia (triplanar), cocok untuk lantai/dinding.
static func mat(color: Color = Color.WHITE, texture_name: String = "", tri: float = 0.0,
		rough: float = 0.8, metal: float = 0.0, emit: Color = Color.BLACK, emit_energy: float = 0.0,
		unshaded: bool = false, double_sided: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if texture_name != "":
		var t := tex(texture_name)
		if t != null:
			m.albedo_texture = t
	if tri > 0.0:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(tri, tri, tri)
	m.roughness = rough
	m.metallic = metal
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_energy
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if double_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, material: Material,
		collide: bool = false, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


static func quad(parent: Node, size: Vector2, pos: Vector3, material: Material,
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func cylinder(parent: Node, top_r: float, bottom_r: float, height: float, pos: Vector3,
		material: Material, collide: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bottom_r
	cm.height = height
	mi.mesh = cm
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = maxf(top_r, bottom_r)
		shape.height = height
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


static func sphere(parent: Node, radius: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi


## Sprite cahaya (additive, selalu menghadap kamera).
static func glow_sprite(parent: Node, size: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex("glow.png")
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return quad(parent, Vector2(size, size), pos, m)


## Mencoba memasang model .glb proyek (mis. Kenney). Return null kalau file tidak ada.
static func try_model(parent: Node, path: String, pos: Vector3, rot_y_deg: float = 0.0,
		scale_mult: float = 1.0) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var res = load(path)
	if res is PackedScene:
		var inst := (res as PackedScene).instantiate() as Node3D
		if inst == null:
			return null
		inst.position = pos
		inst.rotation_degrees.y = rot_y_deg
		inst.scale = Vector3.ONE * scale_mult
		parent.add_child(inst)
		return inst
	return null


## Putar suara sekali (otomatis dibersihkan). loop = true untuk musik/ambient.
static func play(parent: Node, file_name: String, volume_db: float = 0.0, loop: bool = false) -> AudioStreamPlayer:
	var p := SND_DIR + file_name
	if not ResourceLoader.exists(p):
		push_warning("Audio tidak ditemukan: " + p)
		return null
	var stream = load(p)
	if stream == null:
		return null
	if loop and stream is AudioStreamWAV:
		stream = (stream as AudioStreamWAV).duplicate()
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2 # 16-bit mono
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	parent.add_child(player)
	player.play()
	if not loop:
		player.finished.connect(player.queue_free)
	return player


## Label HUD (di CanvasLayer baru). bottom_offset = jarak dari bawah layar (px).
static func make_label(parent: Node, bottom_offset: float, font_size: int = 26) -> Label:
	var layer := CanvasLayer.new()
	layer.layer = 50
	parent.add_child(layer)
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -(bottom_offset + 44.0)
	l.offset_bottom = -bottom_offset
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.visible = false
	layer.add_child(l)
	return l


## Tampilkan pesan sementara pada label.
static func show_msg(owner_node: Node, label: Label, text: String, secs: float) -> void:
	label.text = text
	label.visible = true
	var stamp := Time.get_ticks_msec()
	label.set_meta("stamp", stamp)
	await owner_node.get_tree().create_timer(secs).timeout
	if is_instance_valid(label) and int(label.get_meta("stamp", 0)) == stamp:
		label.visible = false


## Layar fade (hitam/putih) di atas segalanya. Alpha awal = start_alpha.
static func make_fade(parent: Node, color: Color, start_alpha: float) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 100
	parent.add_child(layer)
	var r := ColorRect.new()
	r.color = Color(color.r, color.g, color.b, start_alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	return r


## Pastikan sebuah InputMap action ada (supaya tidak perlu edit Project Settings).
static func ensure_action(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		InputMap.action_add_event(action, ev)
