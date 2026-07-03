extends Node

const SAVE_PATH = "user://audio_settings.cfg"
var master_bus_index: int
var sfx_bus_index: int
var musik_bus_index: int # [BARU] Indeks bus musik

var current_volume: float = 1.0 # Ini Master Volume
var sfx_volume: float = 1.0     # Ini SFX Volume
var musik_volume: float = 1.0   # [BARU] Ini Music Volume
var is_muted: bool = false

# --- PEMUTAR MUSIK (BGM) ---
var bgm_player: AudioStreamPlayer

# PATH MUSIK
var musik_homescreen = preload("res://Assets/Music/train_mainmenu FIX SEMENTARA.ogg") 
var musik_upgrade = preload("res://Assets/Music/upgrade stasion.ogg")
var musik_play = preload("res://Assets/Music/main theme latest.ogg")
var musik_prolog = preload("res://Assets/Music/prolog music.ogg")

# PATH SFX
var sfx_klik = preload("res://Assets/SFX/select button sfx/blipSelect (1).wav")
var sfx_upgrade = preload("res://Assets/SFX/click.wav")

# INGAME OBJECT SFX
var sfx_power_up_pick = preload("res://Assets/SFX/power up/powerUp.wav")
var sfx_crash = preload("res://Assets/SFX/train crash/crash with obstacle (2).wav")
var sfx_destroyed = preload("res://Assets/SFX/Explosion/explosion (2).wav")

# WEAPON SFX
var enemy_laser_charged = preload("res://Assets/SFX/Laser shoot/enemy laserShoot-charged.wav")
var enemy_laser_launched = preload("res://Assets/SFX/Laser shoot/enemy laserShoot 2.wav")
var enemy_rocket_warning = preload("res://Assets/SFX/warning sfx.ogg")	
var enemy_rocket_launched = preload("res://Assets/SFX/Explosion/explosion (6).wav")
var player_laser = preload("res://Assets/SFX/Laser shoot/laserShoot (3).wav")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	master_bus_index = AudioServer.get_bus_index("Master")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	musik_bus_index = AudioServer.get_bus_index("Music") # [BARU] Ambil index bus Music
	
	# 1. SETUP BGM PLAYER
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music" # [UBAH] Arahkan ke bus Music, bukan Master
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
	
func set_sfx_volume(nilai: float):
	sfx_volume = nilai
	terapkan_pengaturan()
	save_audio_settings()

func set_music_volume(nilai: float):
	musik_volume = nilai
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
	
	# SFX Volume
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))
	
	# Music Volume
	AudioServer.set_bus_volume_db(musik_bus_index, linear_to_db(musik_volume))

# --- SISTEM PENYIMPANAN SINKRONOUS ---
func save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("Audio", "volume", current_volume) # Ini Master
	config.set_value("Audio", "sfx_volume", sfx_volume)
	config.set_value("Audio", "musik_volume", musik_volume) # [BARU]
	config.set_value("Audio", "mute", is_muted)
	config.save(SAVE_PATH)

func load_audio_settings():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		current_volume = config.get_value("Audio", "volume", 1.0)
		sfx_volume = config.get_value("Audio", "sfx_volume", 1.0)
		musik_volume = config.get_value("Audio", "musik_volume", 1.0) # [BARU]
		is_muted = config.get_value("Audio", "mute", false)
	else:
		current_volume = 1.0
		sfx_volume = 1.0
		musik_volume = 1.0 # [BARU]
		is_muted = false
