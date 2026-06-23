extends Node2D

# Kecepatan Platform

@export var BASE_SPEED: float = 300.0 
@export var MAX_SPEED: float = 1000.0 
@export var ACCELERATION: float = 15.0 

var current_world_speed: float = 0.0

# Referensi Node
@onready var node_kereta = $Kereta # Ini adalah node yang memakai kereta.gd
@onready var ui_game_over = $CanvasLayer/GameOver
@onready var ui_pause = $CanvasLayer/PauseMenu
@onready var Score = $CanvasLayer/GameOver/VBoxContainer/ScoreLabel
@onready var Coins = $CanvasLayer/GameOver/VBoxContainer/TotalCoin

# Status Permainan
enum GameState { MULAI, BERMAIN, PAUSED, GAME_OVER }
var status_sekarang = GameState.MULAI

func _ready():
	# Inisialisasi Kecepatan Awal
	current_world_speed = BASE_SPEED
	
	# 1. Pastikan UI tertutup saat game mulai
	ui_game_over.hide()
	ui_pause.hide()
	
	# 2. Hubungkan sinyal kekalahan dari kereta.gd ke GameManager
	if is_instance_valid(node_kereta):
		# Asumsinya kita membuat sinyal 'kereta_hancur' di kereta.gd
		node_kereta.connect("kereta_hancur", Callable(self, "_on_game_over"))
		
	mulai_game()
	

func mulai_game():
	status_sekarang = GameState.BERMAIN
	# Bisa tambahkan logika lain seperti hitung mundur 3..2..1 di sini

func _process(delta):
	# Fitur Pause menggunakan tombol Esc
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
		

func _physics_process(delta):
	# LOGIKA AKSELERASI DUNIA
	if status_sekarang == GameState.BERMAIN:
		current_world_speed = move_toward(current_world_speed, MAX_SPEED, ACCELERATION * delta)

# --- LOGIKA PAUSE ---
func toggle_pause():
	if status_sekarang == GameState.GAME_OVER:
		return # Jangan bisa pause kalau sudah mati
		
	if status_sekarang == GameState.BERMAIN:
		status_sekarang = GameState.PAUSED
		get_tree().paused = true # Menghentikan semua _process dan _physics_process
		ui_pause.show()
	else:
		status_sekarang = GameState.BERMAIN
		get_tree().paused = false
		ui_pause.hide()

# --- LOGIKA GAME OVER ---
func _on_game_over():
	status_sekarang = GameState.GAME_OVER
	
	# Panggil penyimpanan data di Autoload
	ScoreManager.finalize_score_and_save()
	
	# Update text UI di layar Game Over
	Score.text = "Score: " + str(int(ScoreManager.current_score))
	Coins.text = "Total Koin: " + str(ScoreManager.accumulated_coin_this_run)
	
	ui_game_over.show()

# --- TOMBOL UI (Hubungkan via Signal Inspector) ---
func _on_btn_restart_pressed():
	# Kembalikan waktu normal jika sebelumnya di-pause
	get_tree().paused = false 
	get_tree().reload_current_scene()

func _on_btn_quit_pressed():
	get_tree().quit()
