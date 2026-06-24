extends Node
# Autoload (singleton) — TIDAK boleh punya referensi $Node ke scene tertentu.
# Tugasnya cuma mengatur state dunia & game flow, lalu memberi tahu scene
# lewat signal. Scene yang mau "dengar" tinggal connect ke signal di bawah.

# Kecepatan Platform
@export var BASE_SPEED: float = 300.0
@export var MAX_SPEED: float = 1000.0
@export var ACCELERATION: float = 15.0

var current_world_speed: float = 0.0

# Status Permainan
enum GameState { MULAI, BERMAIN, PAUSED, GAME_OVER }
var status_sekarang: GameState = GameState.MULAI

# --- SIGNAL: cara GameManager "bicara" ke scene tanpa kenal scene-nya ---
signal game_started
signal game_paused
signal game_resumed
signal game_over_triggered

func _ready():
	current_world_speed = BASE_SPEED

func _process(_delta):
	# Tombol pause global, tidak butuh node manapun
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func _physics_process(delta):
	if status_sekarang == GameState.BERMAIN:
		current_world_speed = move_toward(current_world_speed, MAX_SPEED, ACCELERATION * delta)

func mulai_game():
	status_sekarang = GameState.BERMAIN
	current_world_speed = BASE_SPEED
	# Bisa tambahkan logika hitung mundur 3..2..1 di sini
	game_started.emit()

# --- LOGIKA PAUSE ---
func toggle_pause():
	if status_sekarang == GameState.GAME_OVER:
		return # Jangan bisa pause kalau sudah mati

	if status_sekarang == GameState.BERMAIN:
		status_sekarang = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()
	elif status_sekarang == GameState.PAUSED:
		status_sekarang = GameState.BERMAIN
		get_tree().paused = false
		game_resumed.emit()

# --- LOGIKA GAME OVER ---
# Dipanggil dari scene (lewat sinyal kereta_hancur yang diteruskan, lihat LevelController.gd)
func trigger_game_over():
	if status_sekarang == GameState.GAME_OVER:
		return
	status_sekarang = GameState.GAME_OVER
	ScoreManager.finalize_score_and_save()
	game_over_triggered.emit()

# --- AKSI TOMBOL (dipanggil dari scene) ---
func restart_game():
	get_tree().paused = false
	status_sekarang = GameState.MULAI
	get_tree().reload_current_scene()

func quit_game():
	get_tree().quit()
