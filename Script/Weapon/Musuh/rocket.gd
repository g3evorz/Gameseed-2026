extends Area2D

enum State { WARNING, LAUNCHING }
var current_state: State = State.WARNING

@onready var rocket_sprite: Sprite2D = $RocketSprite
@onready var warning_sprite: Sprite2D = $WarningSprite

@export var damage_tabrakan: int = 200
@export var kekuatan_slow: float = 0.7 
@export var warning_duration: float = 2.0
@export var launch_speed: float = 1.5 # Dibuat lebih cepat untuk horizontal
@export var telegraph_speed: float = 25.0

var _time_passed: float = 0.0

func _ready() -> void:
	set_deferred("monitoring", false)
	body_entered.connect(_on_body_entered)
	_enter_state(State.WARNING)

func _process(delta: float) -> void:
	_time_passed += delta
	
	match current_state:
		State.WARNING:
			# Efek kedip peringatan
			warning_sprite.modulate.a = 0.5 + (sin(_time_passed * telegraph_speed) * 0.5)
			
		State.LAUNCHING:
			# MELUNCUR HORIZONTAL KE KIRI (Seperti Jetpack Joyride)
			position.x -= GameManager.current_world_speed * launch_speed * delta

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.WARNING:
			rocket_sprite.hide()
			warning_sprite.show()
			
			await get_tree().create_timer(warning_duration).timeout
			_enter_state(State.LAUNCHING)
			
		State.LAUNCHING:
			warning_sprite.hide()
			rocket_sprite.show()
			rocket_sprite.modulate.a = 1.0
			set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("terima_damage"):
			body.terima_damage(damage_tabrakan)
		elif body.get_parent() and body.get_parent().has_method("terima_damage"):
			body.get_parent().terima_damage(damage_tabrakan)
			
		GameManager.terapkan_efek_ram(kekuatan_slow)
		queue_free()

# --- TAMBAHAN PENTING ---
# Hancurkan roket jika sudah keluar layar jauh ke kiri agar memori tidak bocor
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
