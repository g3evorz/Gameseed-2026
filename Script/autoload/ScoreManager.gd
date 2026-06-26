extends Node

const SAVE_PATH = "user://game_data.cfg"

# --- DATA UTAMA (Akan Disimpan) ---
var high_score: int = 0
var dompet_koin: int = 0 

# --- DATA UPGRADE (Akan Disimpan) ---
var level_upgrade_laser: int = 0
var level_upgrade_defense: int = 0

# --- DATA RUNTIME (Tidak Disimpan) ---
var current_score: float = 0.0
var accumulated_coin_this_run: int = 0 

@export var SCORE_TO_COIN_RATIO: float = 0.05
@export var SCORE_MULTIPLIER: float = 0.1 # Pengali skor dari jarak

func _ready():	
	load_game_data()

# --- SISTEM SKOR & KOIN BARU (OTOMATIS) ---
func _process(delta):
	# Skor HANYA bertambah jika status game di GameManager adalah BERMAIN
	if GameManager.status_sekarang == GameManager.GameState.BERMAIN:
		# Rumus: Jarak tempuh = Kecepatan GameManager x delta time
		var jarak_tempuh_frame_ini = GameManager.current_world_speed * delta
		current_score += jarak_tempuh_frame_ini * SCORE_MULTIPLIER
		
		# Selalu update dompet koin secara real-time
		update_conversion()

func update_conversion():
	var total_coin_from_score = int(current_score * SCORE_TO_COIN_RATIO)
	var new_coins = total_coin_from_score - accumulated_coin_this_run
	
	if new_coins > 0:
		dompet_koin += new_coins 
		accumulated_coin_this_run += new_coins 

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
func beli_upgrade(harga: int, tipe_upgrade: String) -> bool:
	if dompet_koin >= harga:
		dompet_koin -= harga 
		
		if tipe_upgrade == "laser" and level_upgrade_laser <= 3:
			level_upgrade_laser += 1
		elif tipe_upgrade == "defense" and level_upgrade_defense <= 3:
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

	
	config.save(SAVE_PATH)

func load_game_data():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = config.get_value("Progression", "high_score", 0)
		dompet_koin = config.get_value("Currency", "dompet_koin", 0)
		
		level_upgrade_laser = config.get_value("Upgrades", "level_laser", 0)
		level_upgrade_defense = config.get_value("Upgrades", "level_defense", 0)

	else:
		high_score = 0
		dompet_koin = 0
		level_upgrade_laser = 0
		level_upgrade_defense = 0
