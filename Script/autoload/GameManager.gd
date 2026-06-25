extends Node

# Kecepatan Platform
@export var BASE_SPEED: float = 300.0
@export var MAX_SPEED: float = 1000.0
@export var ACCELERATION: float = 30.0

# Hit and Stop 
@export var HIT_STOP_DURATION: float = 0.8  # Durasi game freeze (dalam detik)
@export var RECOVERY_ACCELERATION: float = 500.0

var is_hit_stopping: bool = false

var current_world_speed: float = 0.0
var normal_acceleration: float = 0.0

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
	if is_hit_stopping:
		return
	
	if status_sekarang == GameState.BERMAIN:
		current_world_speed = move_toward(current_world_speed, MAX_SPEED, ACCELERATION * delta)
		
	if ACCELERATION > normal_acceleration and current_world_speed >= MAX_SPEED - 50.0:
			ACCELERATION = normal_acceleration
			

func terapkan_efek_ram(efek_slow_percent: float):
	if status_sekarang != GameState.BERMAIN:
		return
	current_world_speed -= current_world_speed * efek_slow_percent

	# 2. Freeze sesaat — ini yang menciptakan "feel" hit-stop
	is_hit_stopping = true
	await get_tree().create_timer(HIT_STOP_DURATION, true, false, true).timeout
	is_hit_stopping = false

	# 3. Mulai recovery: akselerasi balik ke MAX_SPEED
	ACCELERATION = RECOVERY_ACCELERATION

	ACCELERATION = RECOVERY_ACCELERATION

func mulai_game():
	status_sekarang = GameState.BERMAIN
	current_world_speed = BASE_SPEED
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
