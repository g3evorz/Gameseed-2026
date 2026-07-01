extends TextureRect # Ubah ke Sprite2D jika Anda tidak menggunakan TextureRect

@export_group("Pengaturan Melayang (Floating)")
@export var kecepatan_melayang: float = 2.0
@export var jarak_melayang_y: float = 15.0
@export var jarak_melayang_x: float = 5.0

@export_group("Pengaturan Rotasi (Wobble)")
@export var kecepatan_rotasi: float = 1.5
@export var batas_kemiringan_derajat: float = 5.0

var posisi_awal: Vector2
var waktu_berjalan: float = 0.0
var offset_waktu_acak: float = 0.0

func _ready():
	posisi_awal = position
	
	# Memberikan waktu mulai yang acak agar setiap planet tidak bergerak serempak
	offset_waktu_acak = randf_range(0.0, 100.0)
	
	# Sedikit mengacak kecepatan agar terasa lebih organik
	kecepatan_melayang += randf_range(-0.5, 0.5)
	kecepatan_rotasi += randf_range(-0.5, 0.5)

func _process(delta):
	# Menambah waktu dengan delta
	waktu_berjalan += delta
	var waktu_aktual = waktu_berjalan + offset_waktu_acak
	
	# Kalkulasi pergerakan naik-turun dan kiri-kanan menggunakan gelombang Sin dan Cos
	var pergerakan_y = sin(waktu_aktual * kecepatan_melayang) * jarak_melayang_y
	var pergerakan_x = cos(waktu_aktual * kecepatan_melayang * 0.8) * jarak_melayang_x
	
	position = posisi_awal + Vector2(pergerakan_x, pergerakan_y)
	
	# Kalkulasi goyangan rotasi
	rotation_degrees = sin(waktu_aktual * kecepatan_rotasi) * batas_kemiringan_derajat
