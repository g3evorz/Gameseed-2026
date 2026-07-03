extends Node

const SAVE_PATH = "user://game_data.cfg"

# --- DATA UTAMA (Akan Disimpan) ---
var high_score: int = 0
var dompet_koin: int = 0 

# --- DATA UPGRADE (Akan Disimpan) ---
var level_upgrade_laser: int = 0
var level_upgrade_defense: int = 0

var sudah_lihat_intro: bool = false
var sudah_lihat_tutorial: bool = false

# --- DATA RUNTIME (Tidak Disimpan) ---
var current_score: float = 0.0

# [BARU] Ini murni untuk menampilkan "Koin Didapat" di layar Game Over
var koin_didapat_run_ini: int = 0 

# [BARU] Ember penampung pecahan koin dari jarak tempuh
var _sisa_pecahan_koin: float = 0.0 

@export var SCORE_TO_COIN_RATIO: float = 0.05
@export var SCORE_MULTIPLIER: float = 0.1 

func _ready():	
	load_game_data()

# --- SISTEM SKOR & KOIN ---
func _process(delta):
	if GameManager.status_sekarang == GameManager.GameState.BERMAIN:
		var jarak_tempuh_frame_ini = GameManager.current_world_speed * delta
		var skor_tambahan = jarak_tempuh_frame_ini * SCORE_MULTIPLIER
		
		# 1. Tambah Skor Utama
		current_score += skor_tambahan
		
		# 2. Masukkan konversi skor ke dalam "ember" pecahan koin
		_sisa_pecahan_koin += skor_tambahan * SCORE_TO_COIN_RATIO
		
		# 3. Jika ember pecahan sudah lebih dari 1 bulat, jadikan koin sungguhan
		if _sisa_pecahan_koin >= 1.0:
			var koin_baru = int(_sisa_pecahan_koin)
			tambah_koin(koin_baru)
			_sisa_pecahan_koin -= koin_baru # Sisakan pecahannya (misal 1.2 - 1.0 = sisa 0.2)

# --- [BARU] FUNGSI PENAMBAH KOIN UNIVERSAL ---
# Gunakan fungsi ini jika pemain mengambil item koin di jalan.
# Contoh memanggilnya dari script lain: ScoreManager.tambah_koin(10)
func tambah_koin(jumlah: int):
	dompet_koin += jumlah
	koin_didapat_run_ini += jumlah

# --- SISTEM AKHIR RUN & RESET ---
func finalize_score_and_save():
	var final_score = int(current_score)
	if final_score > high_score:
		high_score = final_score
		
	save_game_data()

func reset_current_run():
	current_score = 0.0
	koin_didapat_run_ini = 0
	_sisa_pecahan_koin = 0.0

# --- SISTEM PEMBELANJAAN (SHOP) ---
func beli_upgrade(harga: int, tipe_upgrade: String) -> bool:
	if dompet_koin >= harga:
		dompet_koin -= harga 
		
		if tipe_upgrade == "laser" and level_upgrade_laser <= 3:
			level_upgrade_laser += 1
		elif tipe_upgrade  == "defense" and level_upgrade_defense <= 3:
			level_upgrade_defense += 1
			
		save_game_data() 
		return true
	return false

# --- SISTEM PENYIMPANAN SINKRONOUS ---
func save_game_data():
	var config = ConfigFile.new()
	
	config.set_value("Progression", "high_score", high_score)
	config.set_value("Currency", "dompet_koin", dompet_koin)
	
	config.set_value("Upgrades", "level_laser", level_upgrade_laser)
	config.set_value("Upgrades", "level_defense", level_upgrade_defense)
	
	config.set_value("Progress", "sudah_lihat_intro", sudah_lihat_intro)
	config.set_value("Progress", "sudah_lihat_tutorial", sudah_lihat_tutorial)
	
	config.save(SAVE_PATH)

func load_game_data():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = config.get_value("Progression", "high_score", 0)
		dompet_koin = config.get_value("Currency", "dompet_koin", 0)
		
		level_upgrade_laser = config.get_value("Upgrades", "level_laser", 0)
		level_upgrade_defense = config.get_value("Upgrades", "level_defense", 0)
		
		sudah_lihat_intro = config.get_value("Progress", "sudah_lihat_intro", false)
		sudah_lihat_tutorial = config.get_value("Progress", "sudah_lihat_tutorial", false)
	else:
		high_score = 0
		dompet_koin = 0
		level_upgrade_laser = 0
		level_upgrade_defense = 0
