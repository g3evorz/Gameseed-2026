extends Node

const SAVE_PATH = "user://audio_settings.cfg"
var master_bus_index: int

# Variabel penyimpan status audio saat ini
var current_volume: float = 1.0 # 1.0 = 100%, 0.5 = 50%
var is_muted: bool = false

# --- [BARU] VARIABEL MUSIK ---
var bgm_player: AudioStreamPlayer

# GANTI path di bawah ini sesuai dengan lokasi file musik Anda di folder Godot!
# (Bisa format .mp3, .ogg, atau .wav)
var musik_homescreen = preload("res://Assets/Music/train_mainmenu FIX SEMENTARA.wav") 
var musik_upgrade = preload("res://Assets/Music/upgrade stasion.wav")

func _ready():
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# --- [BARU] BUAT PEMUTAR MUSIK DI LATAR BELAKANG ---
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master" 
	add_child(bgm_player)
	# ---------------------------------------------------
	load_audio_settings()
	terapkan_pengaturan()

func putar_musik(track: AudioStream):
	# Jika musik yang diminta sudah sedang diputar, jangan diulang dari awal
	if bgm_player.stream == track and bgm_player.playing:
		return
		
	bgm_player.stream = track
	bgm_player.play()

func hentikan_musik():
	bgm_player.stop()

# Dipanggil oleh UI Slider
func set_volume(nilai: float):
	current_volume = nilai
	terapkan_pengaturan()
	save_audio_settings()

# Dipanggil oleh UI CheckButton (Mute)
func set_mute(kondisi: bool):
	is_muted = kondisi
	terapkan_pengaturan()
	save_audio_settings()

# Mengeksekusi perubahan ke engine Godot
func terapkan_pengaturan():
	# Mute / Unmute
	AudioServer.set_bus_mute(master_bus_index, is_muted)
	
	# Godot menggunakan hitungan Decibel (dB), fungsi linear_to_db akan mengonversi skala 0.0 - 1.0 menjadi dB dengan akurat
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(current_volume))


# --- SISTEM PENYIMPANAN SINKRONOUS ---
func save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("Audio", "volume", current_volume)
	config.set_value("Audio", "mute", is_muted)
	config.save(SAVE_PATH)

func load_audio_settings():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		current_volume = config.get_value("Audio", "volume", 1.0)
		is_muted = config.get_value("Audio", "mute", false)
	else:
		current_volume = 1.0
		is_muted = false
