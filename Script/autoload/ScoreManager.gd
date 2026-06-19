extends Node

const SAVE_PATH = "user://game_data.cfg"

# Data yang akan disimpan
var high_score: int = 0
var total_coin: int = 0

# Skor aktif di dalam runtime permainan
var current_score: float = 0.0
var accumulated_coin: int = 0

# Pengaturan Konversi (100 meter/poin score = 1 Coin)
@export var SCORE_TO_COIN_RATIO: float = 0.01

func _ready():
	load_game_data()

# Menambah skor berdasarkan perpindahan jarak piksel
func add_distance_score(pixel_distance: float):
	# Mengubah jarak piksel menjadi satuan meter/score di dalam game
	# Misal: setiap 10 piksel dihitung sebagai 1 poin skor
	var score_gained = pixel_distance * 0.1
	current_score += score_gained

# Mengonversi skor saat ini menjadi koin (Bisa dipanggil berkala atau saat Game Over)
func update_conversion():
	var total_coin_from_score = int(current_score * SCORE_TO_COIN_RATIO)
	# Cari selisih koin baru yang belum ditambahkan ke total_coin
	var new_coins = total_coin_from_score - accumulated_coin
	if new_coins > 0:
		total_coin += new_coins
		accumulated_coin += new_coins # Catat koin yang sudah dikonversi di rute ini

# Dipanggil saat kereta hancur / Game Over
func finalize_score_and_save():
	update_conversion() # Pastikan koin terakhir sudah dikonversi
	
	var final_score = int(current_score)
	if final_score > high_score:
		high_score = final_score
		
	save_game_data()

# Reset data perjalanan saat pemain mengulang game dari awal (Restart)
func reset_current_run():
	current_score = 0.0
	accumulated_coin = 0

# --- SISTEM PENYIMPANAN SINKRONOUS (ConfigFile) ---
func save_game_data():
	var config = ConfigFile.new()
	config.set_value("Progression", "high_score", high_score)
	config.set_value("Currency", "total_coin", total_coin)
	
	var error = config.save(SAVE_PATH)
	if error != OK:
		print("Gagal menyimpan data game, error code: ", error)

func load_game_data():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error == OK:
		high_score = config.get_value("Progression", "high_score", 0)
		total_coin = config.get_value("Currency", "total_coin", 0)
	else:
		# Jika file belum ada, set data ke default awal
		high_score = 0
		total_coin = 0
