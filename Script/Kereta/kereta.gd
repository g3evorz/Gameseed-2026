extends Node2D

signal kereta_hancur

@onready var kepala_kereta = $Kepala
@onready var sprite_kepala = $Kepala/Sprite2D
@onready var kumpulan_gerbong = $KumpulanGerbong
@onready var label_jumlah_gerbong = $CanvasLayer/LabelJumlahGerbong

@export var JARAK_PIKSEL_ANTAR_GERBONG = 350.0 
@export var KEKAKUAN_DASAR = 15.0 
@export var FAKTOR_AWAL = 0.95 
@export var FAKTOR_PELURUHAN = 0.8 

var rantai_permanen = [] 

# --- Variabel Tambahan untuk Sistem Health & Lose State ---
var max_health: int = 0
var current_health: int = 0
var is_game_over: bool = false
var posisi_x_terakhir: float = 0.0

func _ready():
	ScoreManager.reset_current_run()
	posisi_x_terakhir = kepala_kereta.global_position.x

	var daftar_wadah = kumpulan_gerbong.get_children()
	for i in range(daftar_wadah.size()):
		var gerbong = daftar_wadah[i]
		if gerbong:
			rantai_permanen.append(gerbong) 
			gerbong.global_position.x = kepala_kereta.global_position.x - ((i + 1) * JARAK_PIKSEL_ANTAR_GERBONG)
			gerbong.global_position.y = kepala_kereta.global_position.y
	
	# Inisialisasi Health berdasarkan jumlah gerbong awal
	max_health = rantai_permanen.size()
	current_health = max_health

func _physics_process(delta):
	# Jika game over, hentikan seluruh proses kalkulasi rantai
	if is_game_over:
		return
		
	# --- SISTEM HITUNG SKOR BERDASARKAN JARAK X ---
	var posisi_x_sekarang = kepala_kereta.global_position.x
	var jarak_frame_ini = posisi_x_sekarang - posisi_x_terakhir
	
	if jarak_frame_ini > 0:
		ScoreManager.add_distance_score(jarak_frame_ini)
		ScoreManager.update_conversion() 
	
	posisi_x_terakhir = posisi_x_sekarang

	# --- LOGIKA FISIKA & RANTAI ---
	var kecepatan_sekarang = kepala_kereta.velocity.x
	var sambungan_utuh = true 
	var jumlah_aktif = 0
	
	for i in range(rantai_permanen.size()):
		var gerbong = rantai_permanen[i]
		
		if not is_instance_valid(gerbong) or not gerbong.tersambung:
			sambungan_utuh = false
			continue
			
		if not sambungan_utuh:
			gerbong.putus_sambungan()
			continue 
		
		jumlah_aktif += 1
		
		gerbong.target_x_velocity = kecepatan_sekarang
		gerbong.posisi_y_kepala_absolut = kepala_kereta.global_position.y
		
		if i == 0:
			gerbong.node_target = kepala_kereta
			gerbong.target_rot = sprite_kepala.rotation
		else:
			var gerbong_depan = rantai_permanen[i - 1]
			gerbong.node_target = gerbong_depan
			
			if gerbong_depan.has_node("Sprite2D"):
				gerbong.target_rot = gerbong_depan.get_node("Sprite2D").rotation
			else:
				gerbong.target_rot = gerbong_depan.rotation

		var kalkulasi_kekakuan = KEKAKUAN_DASAR * FAKTOR_AWAL * pow(FAKTOR_PELURUHAN, i)
		gerbong.kekakuan_rantai = max(kalkulasi_kekakuan, 5.0)

	# --- LOGIKA HEALTH & LOSE STATE ---
	# Jika jumlah aktif kurang dari health saat ini, berarti ada gerbong yang putus di frame ini
	if current_health > jumlah_aktif:
		var gerbong_hilang = current_health - jumlah_aktif
		terima_damage(gerbong_hilang)
	
	# Perbarui status health ke jumlah gerbong aktif saat ini
	current_health = jumlah_aktif
		
	if label_jumlah_gerbong:
		label_jumlah_gerbong.text = "Gerbong/Health: " + str(current_health)

	# Jika tidak ada gerbong tersisa, picu Game Over
	if current_health <= 0:
		trigger_game_over()


# Fungsi saat gerbong putus (Bisa untuk menambah efek visual)
func terima_damage(jumlah_hilang: int):
	print("Damage diterima! Kehilangan ", jumlah_hilang, " gerbong.")
	# Anda bisa memanggil efek Camera Shake atau merubah warna sprite kereta menjadi merah sesaat di sini


# Fungsi eksekusi kekalahan
func trigger_game_over():
	is_game_over = true
	
	if is_instance_valid(kepala_kereta) and kepala_kereta.has_method("mati"):
		kepala_kereta.mati()
		
	# Pancarkan sinyal agar Game Manager yang mengurus sisa pekerjaannya (UI & Save)
	emit_signal("kereta_hancur")
