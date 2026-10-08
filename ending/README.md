# Paket Ending - Escape School (Godot 4)

Alur: **Lab Komputer -> ambil kunci -> buka pintu keluar -> Aula Kelulusan -> cahaya di gerbang -> Layar Ending**

## Isi folder `res://ending/`
| Path | Fungsi |
|---|---|
| `scenes/lab_key.tscn` | Kunci emas (berputar, bercahaya). **Taruh di lab** (meja/laci). Tekan E untuk ambil. |
| `scenes/lab_exit_door.tscn` | Pintu keluar lab + papan KELUAR + keypad LED. **Taruh di lubang pintu lab.** |
| `scenes/ending_room.tscn` | Ruang ending (Aula Kelulusan) - bisa dites sendiri dengan F6. |
| `scripts/` | `lab_key.gd`, `lab_exit_door.gd`, `ending_room.gd`, `ending_player.gd`, `ending_ui.gd`, `build_util.gd` |
| `assets/textures/` | floor_tile, wall_paint, door_wood, carpet, banner_selamat, certificate, exit_sign, sign_lab, glow, gate_light, key_icon |
| `assets/audio/` | pickup, locked, door_unlock, door_open, fanfare, ending_music (loop), hall_ambient (loop) |

## Cara pasang (3 langkah)
1. Salin folder `ending/` ke root proyek (jadi `res://ending/`). Buka Godot, tunggu import selesai.
2. Buka `map_komputer.tscn`:
   - Drag `scenes/lab_key.tscn` ke dekat meja/PC, lalu geser ke tempat "persembunyian" kunci.
   - Drag `scenes/lab_exit_door.tscn` ke lubang pintu keluar. Sisi depan pintu = arah **+Z lokal**, putar Y supaya menghadap ke dalam lab.
3. Jalankan. Selesai - tidak perlu mengubah Project Settings (action `interact` = tombol **E** dibuat otomatis).

## Cara kerja kunci
- `lab_key` menyetel metadata `has_key` pada root tree, dan juga `Global.has_key = true` **jika** autoload `Global` punya properti bernama itu.
- `lab_exit_door` membaca dua sumber yang sama. Jika `key.gd`/`global.gd` lama kamu memakai nama variabel lain (mis. `punya_kunci`), ubah `Key Flag` di Inspector pintu & kunci.
- Alternatif: dari script lama panggil `$Pintu.unlock()`.
- Untuk testing tanpa kunci: centang **Debug Always Open** di pintu.

## Pengaturan (Inspector)
- Pintu: `Ending Scene`, `Requires Key`, `Key Flag`, `Door Width/Height`.
- Ruang ending: `Lab Scene` (tujuan tombol "Main Lagi", default `res://map_komputer.tscn`), `Decor Scale` (skala dekorasi Kenney: bangku, tanaman, lampu - otomatis dilewati bila file tidak ada).
- Layar ending: teks kredit & epilog bisa diedit di `ending_ui.gd` (`credits`, `epilogue`).

## Kontrol di Aula
WASD/panah jalan, Shift lari, mouse lihat, Esc lepas/tangkap mouse.

## Catatan
- Semua tekstur & audio dibuat prosedural (bebas lisensi). Script pembuatnya: `gen_textures.py`, `gen_audio.py` (opsional, di luar folder ending).
- Ruangan dibangun lewat kode (primitif + dekorasi Kenney) sehingga tidak ada dependensi ke scene lama.
- Paket ini ditulis untuk Godot 4.x dan belum dijalankan di editor Godot; jika ada error saat pertama kali dibuka, kirim pesan error-nya.
