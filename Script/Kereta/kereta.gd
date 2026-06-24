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
@export var DAMAGE_GERBONG_PUTUS = 200

var is_invincible: bool = false
var timer_invincible: float = 0.0

@export var scene_gerbong: PackedScene

var rantai_permanen = [] 

# --- Variabel Sistem Health & Lose State ---
var max_health: int = 1000
var current_health: int = 0
var is_game_over: bool = false
var posisi_x_terakhir: float = 0.0

# Variabel baru untuk melacak jumlah gerbong frame lalu
var jumlah_gerbong_sebelumnya: int = 0 

func _ready():
	add_to_group("Kereta")
	ScoreManager.reset_current_run()
	posisi_x_terakhir = kepala_kereta.global_position.x

	var daftar_wadah = kumpulan_gerbong.get_children()
	for i in range(daftar_wadah.size()):
		var gerbong = daftar_wadah[i]
		if gerbong:
			rantai_permanen.append(gerbong) 
			gerbong.global_position.x = kepala_kereta.global_position.x - ((i + 1) * JARAK_PIKSEL_ANTAR_GERBONG)
			gerbong.global_position.y = kepala_kereta.global_position.y
	
	# --- APLIKASI UPGRADE DEFENSE ---
	# Misal: Tiap 1 level defense menambah 250 HP pada batas maksimal
	var bonus_hp = ScoreManager.level_upgrade_defense * 250
	max_health = 1000 + bonus_hp
	current_health = max_health
	print("Defense Level ", ScoreManager.level_upgrade_defense, " | HP Total: ", current_health)
	
	# Catat jumlah awal gerbong saat mulai
	jumlah_gerbong_sebelumnya = rantai_permanen.size()


func _physics_process(delta):
	# Jika game over, hentikan seluruh proses kalkulasi rantai
	if is_game_over:
		return
		
	# --- LOGIKA DURASI MODE HANTU ---
	if is_invincible:
		timer_invincible -= delta
		if timer_invincible <= 0:
			matikan_mode_hantu()
		
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

	# --- LOGIKA HEALTH ---
	# Cek jika jumlah gerbong aktif sekarang LEBIH SEDIKIT dari frame sebelumnya
	if jumlah_gerbong_sebelumnya > jumlah_aktif:
		var gerbong_hilang = jumlah_gerbong_sebelumnya - jumlah_aktif
		var total_damage = gerbong_hilang * DAMAGE_GERBONG_PUTUS
		
		print("Gerbong putus! Jumlah: ", gerbong_hilang)
		terima_damage(total_damage)
	
	# Update variabel referensi untuk dicek di frame berikutnya
	jumlah_gerbong_sebelumnya = jumlah_aktif
		
	if label_jumlah_gerbong:
		label_jumlah_gerbong.text = "HP: " + str(current_health) + " | Gerbong: " + str(jumlah_aktif)


# --- FUNGSI DAMAGE UMUM ---
# Fungsi ini dibuat fleksibel sehingga bisa dipanggil dari objek apa saja
func terima_damage(jumlah_damage: int):
	if is_game_over:
		return
		
	current_health -= jumlah_damage
	print("Terkena Damage: ", jumlah_damage, " | Sisa HP: ", current_health)
	
	# Opsional: Tambahkan efek visual berkedip merah atau screen shake di sini
	
	if current_health <= 0:
		current_health = 0 # Cegah HP menjadi minus
		trigger_game_over()

# --- FUNGSI MENGAKTIFKAN/MEMATIKAN MODE HANTU ---
func aktifkan_mode_hantu(durasi: float):
	if is_game_over: return
	
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


func trigger_game_over():
	is_game_over = true
	
	if is_instance_valid(kepala_kereta) and kepala_kereta.has_method("mati"):
		kepala_kereta.mati()
		
	emit_signal("kereta_hancur")
	
	
# --- FUNGSI POWER UP NAMBAH GERBONG ---
func tambah_gerbong():
	if scene_gerbong == null:
		print("ERROR: scene_gerbong belum diisi di Inspector KeretaManager!")
		return
		
	# 1. Spawn wadah/scene gerbong baru
	var gerbong_baru_instans = scene_gerbong.instantiate()
	kumpulan_gerbong.add_child(gerbong_baru_instans)
	
	# 2. Ambil fisikanya (Karena hierarki Anda menggunakan Wadah > CharacterBody2D)
	var gerbong_fisika = gerbong_baru_instans.get_node_or_null("CharacterBody2D")
	
	# Fallback: Jika ternyata gerbong_baru_instans langsung berupa CharacterBody2D
	if gerbong_fisika == null:
		gerbong_fisika = gerbong_baru_instans 
		
	# 3. Cari gerbong paling belakang yang masih hidup untuk menentukan posisi spawn
	var node_paling_belakang = kepala_kereta
	for i in range(rantai_permanen.size() - 1, -1, -1):
		if is_instance_valid(rantai_permanen[i]) and rantai_permanen[i].tersambung:
			node_paling_belakang = rantai_permanen[i]
			break
			
	# 4. Posisikan gerbong baru tepat di belakang gerbong terakhir
	gerbong_fisika.global_position.x = node_paling_belakang.global_position.x - JARAK_PIKSEL_ANTAR_GERBONG
	gerbong_fisika.global_position.y = node_paling_belakang.global_position.y
	
	# 5. Daftarkan ke dalam sistem rantai agar ikut bergerak
	rantai_permanen.append(gerbong_fisika)
	
	# 6. Tambah Darah (HP) & Update Tracker agar tidak dianggap kena damage
	current_health += DAMAGE_GERBONG_PUTUS # Nambah 200 HP
	jumlah_gerbong_sebelumnya += 1 # Sinkronisasi variabel pengecek damage
	
	print("Power Up Gerbong Diambil! HP Sekarang: ", current_health)
