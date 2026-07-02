extends Node2D

@onready var node_kereta = $Kereta # Node yang memakai kereta.gd
@onready var ui_game_over = $CanvasLayer/GameOver
@onready var ui_pause = $CanvasLayer/PauseMenu
@onready var score_label = $CanvasLayer/GameOver/VBoxContainer/ScoreLabel
@onready var coin_label = $CanvasLayer/GameOver/VBoxContainer/TotalCoin
@onready var confirmation_panel = $CanvasLayer/ConfirmationPanel

func _ready():
	ui_game_over.hide()
	ui_pause.hide()
	AudioManager.putar_musik(AudioManager.musik_play)
	if is_instance_valid(node_kereta):
		node_kereta.connect("kereta_hancur", Callable(self, "_on_kereta_hancur"))
	_play_animasi_kereta()
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	GameManager.game_over_triggered.connect(_on_game_over)
	
	GameManager.mulai_game()

func _on_kereta_hancur():
	GameManager.trigger_game_over()

func _on_game_paused():
	ui_pause.show()

func _on_game_resumed():
	ui_pause.hide()

func _on_game_over():
	score_label.text = "Score: " + str(int(ScoreManager.current_score))
	
	# Menampilkan koin ronde ini DAN total saldo di dompet
	coin_label.text = "Koin Didapat: " + str(ScoreManager.accumulated_coin_this_run) + " | Saldo: " + str(ScoreManager.dompet_koin)
	
	ui_game_over.show()

# --- TOMBOL UI (hubungkan via Signal Inspector seperti sebelumnya) ---
func _on_btn_restart_pressed():
	AudioManager.putar_musik(AudioManager.musik_play)
	GameManager.restart_game()

func _on_btn_quit_pressed():
	confirmation_panel.tampilkan("Return?")
	

func _on_confirmation_panel_konfirmasi_ya():
	get_tree().paused = false
	GameManager.status_sekarang = GameManager.GameState.MULAI
	SceneTransition.pindah_scene("res://Scenes/Upgradable.tscn")
	
func _on_pause_button_pressed() -> void:
	GameManager.toggle_pause()


func _on_resume_pressed() -> void:
	GameManager.toggle_pause()
	
func _play_animasi_kereta():
	$Kereta/Kepala/Sprite2D.play("default")
	$Kereta/KumpulanGerbong/Gerbong1/Sprite2D.play("default")
	$Kereta/KumpulanGerbong/Gerbong2/Sprite2D.play("default")
	$Kereta/KumpulanGerbong/Gerbong3/Sprite2D.play("default")
	$Kereta/KumpulanGerbong/Gerbong4/Sprite2D.play("default")
	
