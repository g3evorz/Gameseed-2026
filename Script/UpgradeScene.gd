extends CanvasLayer # Atau Node2D, sesuaikan dengan tipe node 'Main' Anda

# --- REFERENSI NODE BERDASARKAN HIRARKI BARU ---
@onready var label_dompet = $MarginUang/HBoxUang/LabelDompet

# Node Item Laser
@onready var label_lvl_laser = $MarginUpgrade/HBoxUpgrade/ItemLaser/Label
@onready var btn_beli_laser = $MarginUpgrade/HBoxUpgrade/ItemLaser/Button

# Node Item Defense
@onready var label_lvl_defense = $MarginUpgrade/HBoxUpgrade/ItemDefense/Label
@onready var btn_beli_defense = $MarginUpgrade/HBoxUpgrade/ItemDefense/Button

# --- KONFIGURASI HARGA (Harga Dasar & Kelipatan per Level) ---
var harga_dasar_laser = 200
var kelipatan_harga_laser = 200

var harga_dasar_defense = 150
var kelipatan_harga_defense = 100

func _ready():
	# Muat data dari save file saat menu dibuka
	AudioManager.putar_musik(AudioManager.musik_upgrade)
	ScoreManager.load_game_data()
	update_semua_ui()

# --- FUNGSI UPDATE TAMPILAN UI ---
func update_semua_ui():
	# Update Teks Dompet
	label_dompet.text = "Saldo Koin: " + str(ScoreManager.dompet_koin)
	
	# 1. Update UI Laser
	var level_l = ScoreManager.level_upgrade_laser
	var harga_l = hitung_harga(harga_dasar_laser, kelipatan_harga_laser, level_l)
	label_lvl_laser.text = "Laser (Lvl " + str(level_l) + ")"
	btn_beli_laser.text = "Beli: " + str(harga_l)
	btn_beli_laser.disabled = ScoreManager.dompet_koin < harga_l # Matikan tombol jika uang kurang
	
	# 2. Update UI Defense
	var level_d = ScoreManager.level_upgrade_defense
	var harga_d = hitung_harga(harga_dasar_defense, kelipatan_harga_defense, level_d)
	label_lvl_defense.text = "Defense (Lvl " + str(level_d) + ")"
	btn_beli_defense.text = "Beli: " + str(harga_d)
	btn_beli_defense.disabled = ScoreManager.dompet_koin < harga_d
	

# Fungsi bantuan untuk menghitung harga dinamis
func hitung_harga(dasar: int, kelipatan: int, level_saat_ini: int) -> int:
	return dasar + (kelipatan * level_saat_ini)

# --- FUNGSI KLIK TOMBOL BELI (Hubungkan via Inspector ke masing-masing Button) ---

func _on_btn_beli_laser_pressed():
	if ScoreManager.level_upgrade_laser <= 3:
		var harga = hitung_harga(harga_dasar_laser, kelipatan_harga_laser, ScoreManager.level_upgrade_laser)
		if ScoreManager.beli_upgrade(harga, "laser"):
			update_semua_ui()

func _on_btn_beli_defense_pressed():
	if ScoreManager.level_upgrade_defense <= 3:
		var harga = hitung_harga(harga_dasar_defense, kelipatan_harga_defense, ScoreManager.level_upgrade_defense)
		if ScoreManager.beli_upgrade(harga, "defense"):
			update_semua_ui()

# --- FUNGSI NAVIGASI ---

func _on_button_home_pressed():
	SceneTransition.pindah_scene("res://Scenes/Homescreen.tscn")

func _on_button_start_pressed():
	SceneTransition.pindah_scene("res://Scenes/main.tscn")
