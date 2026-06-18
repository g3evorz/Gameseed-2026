extends Node2D

@onready var kepala_kereta = $Kepala/CharacterBody2D
@onready var sprite_kepala = $Kepala/CharacterBody2D/Sprite2D
@onready var kumpulan_gerbong = $KumpulanGerbong

@export var JARAK_PIKSEL_ANTAR_GERBONG = 270.0 
@export var KEKAKUAN_DASAR = 15.0 
@export var FAKTOR_AWAL = 0.95 
@export var FAKTOR_PELURUHAN = 0.8 

# Array ini tidak akan pernah berubah (menyimpan cetak biru awal)
var rantai_permanen = [] 

func _ready():
	var daftar_wadah = kumpulan_gerbong.get_children()
	for i in range(daftar_wadah.size()):
		var gerbong = daftar_wadah[i].get_node_or_null("CharacterBody2D")
		if gerbong:
			# Masukkan ke catatan manajer
			rantai_permanen.append(gerbong) 
			
			gerbong.global_position.x = kepala_kereta.global_position.x - ((i + 1) * JARAK_PIKSEL_ANTAR_GERBONG)
			gerbong.global_position.y = kepala_kereta.global_position.y

func _physics_process(_delta):
	var kecepatan_sekarang = kepala_kereta.velocity.x
	
	# Variabel untuk mendeteksi apakah aliran tarikan dari depan masih utuh
	var sambungan_utuh = true 
	
	for i in range(rantai_permanen.size()):
		var gerbong = rantai_permanen[i]
		
		# Jika memori gerbong ini sudah dihapus (queue_free), rantai putus di sini!
		if not is_instance_valid(gerbong):
			sambungan_utuh = false
			continue
			
		# Jika gerbong ini sudah dinyatakan "putus" oleh scriptnya sendiri
		if not gerbong.tersambung:
			sambungan_utuh = false
			continue
			
		# JIKA ADA GERBONG DEPAN YANG PUTUS, GERBONG INI JUGA HARUS IKUT PUTUS
		if not sambungan_utuh:
			gerbong.putus_sambungan()
			continue # Lewati pemberian kecepatan agar dia mengerem

		# --- Jika sambungan aman, terus berikan tarikan ---
		gerbong.target_x_velocity = kecepatan_sekarang
		gerbong.posisi_x_kepala = kepala_kereta.global_position.x
		
		# Tentukan siapa yang ditiru
		if i == 0:
			gerbong.target_y = kepala_kereta.global_position.y
			gerbong.target_rot = sprite_kepala.rotation
			gerbong.target_vel_y = kepala_kereta.velocity.y
			gerbong.target_di_tanah = kepala_kereta.is_on_floor()
		else:
			var gerbong_depan = rantai_permanen[i - 1]
			# Karena kita mengecek sambungan_utuh di atas, kita tahu pasti gerbong_depan itu valid
			gerbong.target_y = gerbong_depan.global_position.y
			gerbong.target_rot = gerbong_depan.rotation
			gerbong.target_vel_y = gerbong_depan.velocity.y
			gerbong.target_di_tanah = gerbong_depan.is_on_floor()
				
		gerbong.kekakuan_rantai = KEKAKUAN_DASAR * FAKTOR_AWAL * pow(FAKTOR_PELURUHAN, i)

# ... (Fungsi picu_lompat_berantai() tetap sama, cukup pastikan dia juga mengecek gerbong.tersambung sebelum menyuruh lompat)
