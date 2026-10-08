extends CanvasLayer
## Layar ENDING: judul, cerita penutup, statistik, kredit bergulir, tombol "Main Lagi" / "Keluar".
## Dibuat sepenuhnya lewat kode; dipanggil oleh ending_room.gd -> show_ending(elapsed_seconds).

const GOLD := Color(1.0, 0.82, 0.3)

@export_file("*.tscn") var lab_scene: String = "res://map_komputer.tscn"
@export var key_flag: String = "has_key"
@export_multiline var epilogue: String = "Bel sekolah berbunyi. Pintu lab terbuka dan cahaya pagi menyambutmu.\nSemua teka-teki sudah terpecahkan - kamu resmi LULUS dari Escape School!"
@export_multiline var credits: String = "ESCAPE SCHOOL\n\nDibuat oleh\nluthfianapia2\n\nASET 3D\nFurniture Kit - Kenney\nBlackboard - Poly by Google\nBookshelf - Wanja Pfluger\nCubicle - Stephen Faett\nOffice Chair - Quaternius\nPrinter - Mikael Ganehag Brorsson\nProfessional PC - Lokey\nDesk - dook\n\nASET RUANG ENDING\nTekstur & audio dibuat prosedural\n\nTerima kasih sudah bermain!"

var _root: Control


func show_ending(elapsed_seconds: float) -> void:
	layer = 110
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.modulate.a = 0.0
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.09, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(680, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	box.add_child(_label("SELAMAT!", 76, GOLD))
	box.add_child(_label("Kamu berhasil keluar dari Escape School", 28, Color.WHITE))
	box.add_child(_label(epilogue, 18, Color(0.8, 0.85, 0.95)))
	box.add_child(HSeparator.new())
	box.add_child(_label(_stats_text(elapsed_seconds), 22, Color(0.7, 1.0, 0.8)))
	box.add_child(HSeparator.new())
	box.add_child(_build_credits())

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var again := _button("Main Lagi")
	var quit := _button("Keluar")
	again.pressed.connect(_on_restart)
	quit.pressed.connect(func(): get_tree().quit())
	row.add_child(again)
	row.add_child(quit)

	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 1.2)
	again.grab_focus()


func _stats_text(elapsed: float) -> String:
	var time_str := "-"
	var rank := "-"
	if elapsed >= 0.0:
		var m := int(elapsed) / 60
		var s := int(elapsed) % 60
		time_str = "%02d:%02d" % [m, s]
		if elapsed < 300.0:
			rank = "S - Jenius Lab"
		elif elapsed < 600.0:
			rank = "A - Murid Teladan"
		elif elapsed < 1200.0:
			rank = "B - Lulus Dengan Baik"
		else:
			rank = "C - Lulus Tipis-tipis"
	return "Waktu kabur: %s      Kunci ditemukan: Ya      Peringkat: %s" % [time_str, rank]


func _build_credits() -> Control:
	var clip := Control.new()
	clip.custom_minimum_size = Vector2(680, 150)
	clip.clip_contents = true
	var lbl := Label.new()
	lbl.text = credits
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	lbl.custom_minimum_size = Vector2(680, 0)
	clip.add_child(lbl)
	var h := float(credits.count("\n") + 1) * 26.0
	var tw := create_tween().set_loops()
	tw.tween_property(lbl, "position:y", -h, maxf(12.0, h / 28.0)).from(150.0)
	return clip


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(210, 54)
	b.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.16, 0.22, 0.4)
	normal.set_corner_radius_all(12)
	normal.border_color = GOLD
	normal.set_border_width_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.24, 0.34, 0.6)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	return b


func _on_restart() -> void:
	var root := get_tree().root
	for k in [key_flag, "escape_start_msec"]:
		if root.has_meta(k):
			root.remove_meta(k)
	var g := get_node_or_null("/root/Global")
	if g != null and g.get(key_flag) != null:
		g.set(key_flag, false)
	if ResourceLoader.exists(lab_scene):
		get_tree().change_scene_to_file(lab_scene)
	else:
		get_tree().reload_current_scene()
