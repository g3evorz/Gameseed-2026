extends Node2D

@onready var kepala_kereta = $Kepala/CharacterBody2D
@onready var sprite_kepala = $Kepala/CharacterBody2D/Sprite2D
@onready var kumpulan_gerbong = $KumpulanGerbong

@export var MAKSIMAL_GERBONG = 10 
@export var JARAK_PIKSEL_ANTAR_GERBONG = 270 

# Angka ini menentukan seberapa kaku/elastis sambungan keretanya.
# - Semakin besar (misal 20.0), gerbong akan bereaksi sangat cepat (kaku).
# - Semakin kecil (misal 5.0), gerbong akan melar dan lambat ditarik.
@export var KEKAKUAN_RANTAI = 15.0 
@export var FAKTOR_AWAL = 0.9
@export var FAKTOR_PELURUHAN = 0.8

func _physics_process(delta):
	var daftar_gerbong = kumpulan_gerbong.get_children()
	
	for i in range(daftar_gerbong.size()):
		if i >= MAKSIMAL_GERBONG:
			break
			
		var gerbong = daftar_gerbong[i]
		
		# 1. KUNCI SUMBU X: Jarak horizontal dijamin tetap absolut & rapi
		gerbong.global_position.x = kepala_kereta.global_position.x - ((i + 1) * JARAK_PIKSEL_ANTAR_GERBONG)
		
		# 2. TENTUKAN TARGET (Siapa yang harus diikuti oleh gerbong ini?)
		var target_y = 0.0
		var target_rot = 0.0
		
		if i == 0:
			# Gerbong pertama selalu meniru Kepala secara langsung
			target_y = kepala_kereta.global_position.y
			target_rot = sprite_kepala.rotation
		else:
			# Gerbong ke-2 dan seterusnya meniru gerbong tepat di depannya (i - 1)
			var gerbong_depan = daftar_gerbong[i - 1]
			target_y = gerbong_depan.global_position.y
			target_rot = gerbong_depan.rotation
			
		# --- REVISI: KALKULASI KEKAKUAN DINAMIS ---
		# Menggunakan fungsi matematika pow (pangkat) untuk menciptakan penurunan kurva yang halus.
		# i=0 -> pow(0.8, 0) = 1.0  (Kekuatan 100%)
		# i=1 -> pow(0.8, 1) = 0.8  (Kekuatan 80%)
		# i=2 -> pow(0.8, 2) = 0.64 (Kekuatan 64%)
		# i=3 -> pow(0.8, 3) = 0.51 (Kekuatan 51%)
		var kekakuan_dinamis = KEKAKUAN_RANTAI * FAKTOR_AWAL * pow(FAKTOR_PELURUHAN, i)
		
		gerbong.global_position.y = lerp(gerbong.global_position.y, target_y, kekakuan_dinamis * delta)
		gerbong.rotation = lerp_angle(gerbong.rotation, target_rot, kekakuan_dinamis * delta)
