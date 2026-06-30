extends CanvasLayer

@onready var animation_player = $AnimationPlayer
@onready var color_rect = $ColorRect

# Variabel penyimpan alamat scene tujuan
var path_tujuan: String = ""

func _ready():
	# Pastikan saat game baru mulai, layarnya transparan
	color_rect.color.a = 0.0

# Fungsi yang akan dipanggil oleh tombol dari scene lain
func pindah_scene(target_path: String):
	animation_player.play("fade_in")
	print("animasi di play")
	path_tujuan = target_path
	

# --- PENGGANTI ASYNC: KONEKSI SINYAL ---
func _on_animation_player_animation_finished(anim_name):
	# Jika layar sudah selesai menjadi gelap total...animation_player
	await get_tree().create_timer(0.5).timeout
	if anim_name == "fade_in":
		# 1. Pindah scene di belakang layar
		get_tree().change_scene_to_file(path_tujuan)
		
		# 2. Setelah pindah, langsung mainkan animasi terang kembali
		animation_player.play("fade_out")
