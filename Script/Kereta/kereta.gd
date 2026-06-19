extends Node2D

@onready var kepala_kereta = $Kepala/CharacterBody2D
@onready var sprite_kepala = $Kepala/CharacterBody2D/Sprite2D
@onready var kumpulan_gerbong = $KumpulanGerbong
@onready var label_jumlah_gerbong = $CanvasLayer/LabelJumlahGerbong

@export var JARAK_PIKSEL_ANTAR_GERBONG = 350.0 
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
			# Gerbong 1 menargetkan Kepala Kereta
			gerbong.node_target = kepala_kereta
			gerbong.target_rot = sprite_kepala.rotation
		else:
			# Gerbong 2+ menargetkan Gerbong di depannya
			var gerbong_depan = rantai_permanen[i - 1]
			gerbong.node_target = gerbong_depan
			
			if gerbong_depan.has_node("Sprite2D"):
				gerbong.target_rot = gerbong_depan.get_node("Sprite2D").rotation
			else:
				gerbong.target_rot = gerbong_depan.rotation

		var kalkulasi_kekakuan = KEKAKUAN_DASAR * FAKTOR_AWAL * pow(FAKTOR_PELURUHAN, i)
		gerbong.kekakuan_rantai = max(kalkulasi_kekakuan, 5.0)
		
	if label_jumlah_gerbong:
			label_jumlah_gerbong.text = "Gerbong Aktif: " + str(jumlah_aktif)
