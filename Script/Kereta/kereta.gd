extends Node2D

@onready var kepala_kereta = $Kepala
@onready var sprite_kepala = $Kepala/Sprite2D
@onready var kumpulan_gerbong = $KumpulanGerbong
@onready var label_jumlah_gerbong = $CanvasLayer/MarginContainer/LabelJumlahGerbong

@export var JARAK_PIKSEL_ANTAR_GERBONG = 350.0 
@export var KEKAKUAN_DASAR = 15.0 
@export var FAKTOR_AWAL = 0.95 
@export var FAKTOR_PELURUHAN = 0.8
@export var DAMAGE_GERBONG_PUTUS = 200

@export var IMMUNITY_TIMER = 4.0
@export var SPAWN_GERBONG_OFFSITE = 2000.0
@export var scene_gerbong: PackedScene

var rantai_permanen = [] 

# --- Variabel Sistem Health & Mode Hantu ---
var max_health: int = 1000
var current_health: int = 0
var jumlah_gerbong_sebelumnya: int = 0 

var is_invincible: bool = false
var timer_invincible: float = 0.0

func _ready():
	add_to_group("Kereta")
	
	# Sambungkan pendeteksi Game Over dari GameManager
	GameManager.game_over_triggered.connect(_eksekusi_kematian_kereta)

	var daftar_wadah = kumpulan_gerbong.get_children()
	for i in range(daftar_wadah.size()):
		var gerbong = daftar_wadah[i]
		if gerbong:
			rantai_permanen.append(gerbong) 
			gerbong.global_position.x = kepala_kereta.global_position.x - ((i + 1) * JARAK_PIKSEL_ANTAR_GERBONG)
			gerbong.global_position.y = kepala_kereta.global_position.y
	
	var bonus_hp = ScoreManager.level_upgrade_defense * 250
	max_health = 1000 + bonus_hp
	current_health = max_health
	
	jumlah_gerbong_sebelumnya = rantai_permanen.size()


# PERBAIKAN: Ubah _delta menjadi delta (hapus garis bawah) agar timer bisa membaca waktu
func _physics_process(delta):
	# Gunakan GameManager sebagai patokan jalan tidaknya game
	if GameManager.status_sekarang != GameManager.GameState.BERMAIN:
		return
		
	# --- LOGIKA DURASI MODE HANTU ---
	if is_invincible:
		timer_invincible -= delta
		if timer_invincible <= 0:
			matikan_mode_hantu()

	# --- LOGIKA FISIKA & RANTAI ---
	var kecepatan_sekarang = kepala_kereta.velocity.x
	var sambungan_utuh = true 
	var jumlah_aktif = 0
	var rantai_sehat = []
	
	for i in range(rantai_permanen.size()):
		var gerbong = rantai_permanen[i]
		
		if not is_instance_valid(gerbong) or not gerbong.tersambung:
			sambungan_utuh = false
			continue
			
		if not sambungan_utuh:
			gerbong.putus_sambungan()
			continue 
		
		jumlah_aktif += 1
		rantai_sehat.append(gerbong) 
		
		gerbong.target_x_velocity = kecepatan_sekarang
		gerbong.posisi_y_kepala_absolut = kepala_kereta.global_position.y
		
		if "FAST_FALL_VELOCITY" in kepala_kereta:
			gerbong.FAST_FALL_VELOCITY = kepala_kereta.FAST_FALL_VELOCITY
		
		if i == 0:
			gerbong.node_target = kepala_kereta
			gerbong.target_rot = sprite_kepala.rotation
		else:
			var gerbong_depan = rantai_sehat[jumlah_aktif - 2]
			gerbong.node_target = gerbong_depan
			
			if gerbong_depan.has_node("Sprite2D"):
				gerbong.target_rot = gerbong_depan.get_node("Sprite2D").rotation
			else:
				gerbong.target_rot = gerbong_depan.rotation
				
		var kalkulasi_kekakuan = KEKAKUAN_DASAR * FAKTOR_AWAL * pow(FAKTOR_PELURUHAN, i)
		gerbong.kekakuan_rantai = max(kalkulasi_kekakuan, 5.0)
		
	rantai_permanen = rantai_sehat
	
	# --- LOGIKA HEALTH ---
	if jumlah_gerbong_sebelumnya > jumlah_aktif:
		var gerbong_hilang = jumlah_gerbong_sebelumnya - jumlah_aktif
		var total_damage = gerbong_hilang * DAMAGE_GERBONG_PUTUS
		terima_damage(total_damage)
	
	jumlah_gerbong_sebelumnya = jumlah_aktif
		
	if label_jumlah_gerbong:
		label_jumlah_gerbong.text = "HP: " + str(current_health) + " | Gerbong: " + str(jumlah_aktif)


# --- FUNGSI MENGAKTIFKAN/MEMATIKAN MODE HANTU ---
func ghost_mode(durasi: float):
	# PERBAIKAN: Gunakan GameManager untuk mengecek status game
	if GameManager.status_sekarang != GameManager.GameState.BERMAIN: return
	
	is_invincible = true
	timer_invincible = durasi

	print("Mode Hantu Aktif selama ", durasi, " detik!")
	
	# Ubah Kepala menjadi semi-transparan (Alpha = 0.5)
	if is_instance_valid(sprite_kepala):
		sprite_kepala.modulate.a = 0.5
		
	# Ubah seluruh Gerbong menjadi semi-transparan
	for gerbong in rantai_permanen:
		if is_instance_valid(gerbong) and gerbong.has_node("Sprite2D"):
			gerbong.get_node("Sprite2D").modulate.a = 0.5

func matikan_mode_hantu():
	is_invincible = false
	print("Mode Hantu Berakhir, kembali normal!")
	
	# Kembalikan Kepala menjadi solid (Alpha = 1.0)
	if is_instance_valid(sprite_kepala):
		sprite_kepala.modulate.a = 1.0
		
	# Kembalikan seluruh Gerbong menjadi solid
	for gerbong in rantai_permanen:
		if is_instance_valid(gerbong) and gerbong.has_node("Sprite2D"):
			gerbong.get_node("Sprite2D").modulate.a = 1.0


# --- FUNGSI DAMAGE & GAME OVER ---
func terima_damage(jumlah_damage: int):
	if GameManager.status_sekarang != GameManager.GameState.BERMAIN:
		return
		
	# PERBAIKAN: Kebal terhadap damage saat Ghost Mode aktif
	if is_invincible:
		print("Kereta sedang Ghost Mode! Kebal damage.")
		return
		
	current_health -= jumlah_damage
	
	if current_health <= 0:
		current_health = 0 
		GameManager.trigger_game_over() # Lapor ke GameManager

func _eksekusi_kematian_kereta():
	if is_instance_valid(kepala_kereta) and kepala_kereta.has_method("mati"):
		kepala_kereta.mati()
	
# --- FUNGSI POWER UP NAMBAH GERBONG ---
func tambah_gerbong():
	if scene_gerbong == null:
		return
		
	var gerbong_baru_instans = scene_gerbong.instantiate()
	var gerbong_fisika = gerbong_baru_instans.get_node_or_null("CharacterBody2D")
	
	if gerbong_fisika == null:
		gerbong_fisika = gerbong_baru_instans 
		
	# Pencarian gerbong terakhir lebih efisien menggunakan .back()
	var node_paling_belakang = kepala_kereta
	if rantai_permanen.size() > 0:
		node_paling_belakang = rantai_permanen.back()
	
	gerbong_fisika.global_position.x = node_paling_belakang.global_position.x - SPAWN_GERBONG_OFFSITE
	gerbong_fisika.global_position.y = node_paling_belakang.global_position.y
	
	if "timer_imunitas" in gerbong_fisika:
		gerbong_fisika.timer_imunitas = IMMUNITY_TIMER
	
	rantai_permanen.append(gerbong_fisika)
	
	# Memastikan penambahan node ditunda agar tidak crash dengan physics query saat menabrak item
	kumpulan_gerbong.call_deferred("add_child", gerbong_baru_instans)
	
	current_health += DAMAGE_GERBONG_PUTUS
	jumlah_gerbong_sebelumnya += 1
