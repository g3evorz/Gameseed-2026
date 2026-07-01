extends Node

const SAVE_PATH = "user://audio_settings.cfg"
var master_bus_index: int
var sfx_bus_index: int

var current_volume: float = 1.0
var is_muted: bool = false

# --- PEMUTAR MUSIK (BGM) ---
var bgm_player: AudioStreamPlayer

# PATH MUSIK
var musik_homescreen = preload("res://Assets/Music/train_mainmenu FIX SEMENTARA.wav") 
var musik_upgrade = preload("res://Assets/Music/upgrade stasion.wav")
var musik_play = preload("res://Assets/Music/main theme latest.wav")

# PATH SFX
var sfx_klik = preload("res://Assets/SFX/select button sfx/blipSelect (1).wav")
var sfx_upgrade = preload("res://Assets/SFX/click.wav")

func _ready():
	master_bus_index = AudioServer.get_bus_index("Master")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	# 1. SETUP BGM PLAYER (Hanya dibuat sekali)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	# Penting: Jangan hubungkan sinyal 'finished' ke BGM player
	add_child(bgm_player)
	
	load_audio_settings()
	terapkan_pengaturan()

# --- FUNGSI MUSIK (BGM) ---
func putar_musik(track: AudioStream):
	# Jika musik sama dan sedang diputar, biarkan
	if bgm_player.stream == track and bgm_player.playing:
		return
		
	bgm_player.stream = track
	bgm_player.play()

# --- FUNGSI SFX (EFEK SUARA) ---
func putar_sfx(track: AudioStream):
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = track
	
	# [PENTING] Arahkan ke bus SFX agar bisa diatur volumenya secara terpisah
	sfx_player.bus = "SFX" 
	
	add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()

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
