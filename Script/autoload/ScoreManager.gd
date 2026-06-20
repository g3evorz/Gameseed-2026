extends Node

const SAVE_PATH = "user://game_data.cfg"

# --- DATA UTAMA (Akan Disimpan) ---
var high_score: int = 0
var dompet_koin: int = 0 # Ini sekarang berfungsi sebagai saldo akumulasi

# --- DATA UPGRADE (Akan Disimpan) ---
# Contoh: Kita buat 2 jenis upgrade
var level_upgrade_gerbong: int = 0 # Menambah jumlah gerbong awal (Health)
var level_upgrade_mesin: int = 0   # Menambah kecepatan awal kereta

# --- DATA RUNTIME (Tidak Disimpan) ---
var current_score: float = 0.0
var accumulated_coin_this_run: int = 0 # Mencatat koin yang didapat HANYA pada run/jalan kali ini

@export var SCORE_TO_COIN_RATIO: float = 0.05

func _ready():	
	load_game_data()

# --- SISTEM SKOR & KOIN GAMEPLAY ---
func add_distance_score(pixel_distance: float):
	var score_gained = pixel_distance * 0.1
	current_score += score_gained

func update_conversion():
	var total_coin_from_score = int(current_score * SCORE_TO_COIN_RATIO)
	var new_coins = total_coin_from_score - accumulated_coin_this_run
	
	if new_coins > 0:
		dompet_koin += new_coins # Masukkan ke dompet utama
		accumulated_coin_this_run += new_coins # Catat bahwa koin ini sudah diklaim di run ini

func finalize_score_and_save():
	update_conversion() 
	
	var final_score = int(current_score)
	if final_score > high_score:
		high_score = final_score
		
	save_game_data()

func reset_current_run():
	current_score = 0.0
	accumulated_coin_this_run = 0

# --- SISTEM PEMBELANJAAN (SHOP) ---
# Fungsi ini dipanggil oleh tombol di UI Shop Menu
func beli_upgrade(harga: int, tipe_upgrade: String) -> bool:
	if dompet_koin >= harga:
		dompet_koin -= harga # Potong saldo koin
		
		# Terapkan level upgrade
		if tipe_upgrade == "gerbong":
			level_upgrade_gerbong += 1
		elif tipe_upgrade == "mesin":
			level_upgrade_mesin += 1
			
		print("Upgrade berhasil! Sisa Koin: ", dompet_koin)
		save_game_data() # Langsung simpan data agar tidak hilang jika game diclose
		return true
	else:
		print("Koin tidak cukup!")
		return false

# --- SISTEM PENYIMPANAN SINKRONOUS ---
func save_game_data():
	var config = ConfigFile.new()
	
	# Simpan Progresi & Uang
	config.set_value("Progression", "high_score", high_score)
	config.set_value("Currency", "dompet_koin", dompet_koin)
	
	# Simpan Level Upgrade
	config.set_value("Upgrades", "level_gerbong", level_upgrade_gerbong)
	config.set_value("Upgrades", "level_mesin", level_upgrade_mesin)
	
	config.save(SAVE_PATH)

func load_game_data():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error == OK:
		high_score = config.get_value("Progression", "high_score", 0)
		dompet_koin = config.get_value("Currency", "dompet_koin", 0)
		
		level_upgrade_gerbong = config.get_value("Upgrades", "level_gerbong", 0)
		level_upgrade_mesin = config.get_value("Upgrades", "level_mesin", 0)
	else:
		# Jika file belum ada (Pemain Baru)
		high_score = 0
		dompet_koin = 0
		level_upgrade_gerbong = 0
		level_upgrade_mesin = 0
