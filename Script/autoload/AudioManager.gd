extends Node

const SAVE_PATH = "user://audio_settings.cfg"
var master_bus_index: int

# Variabel penyimpan status audio saat ini
var current_volume: float = 1.0 # 1.0 = 100%, 0.5 = 50%
var is_muted: bool = false

func _ready():
	# Mengambil indeks dari Bus "Master" bawaan Godot
	master_bus_index = AudioServer.get_bus_index("Master")
	
	load_audio_settings()
	terapkan_pengaturan()

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
