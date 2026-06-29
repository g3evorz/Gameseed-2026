extends Area2D

enum State { WARNING, LAUNCHING }
var current_state: State = State.WARNING

@onready var rocket_sprite: Sprite2D = $RocketSprite
@onready var warning_sprite: Sprite2D = $WarningSprite

@export var damage_tabrakan: int = 200
@export var kekuatan_slow: float = 0.7 
@export var warning_duration: float = 2.0
@export var launch_speed: float = 1.8
@export var telegraph_speed: float = 25.0
@export var base_lock_on_speed: float = 6.0  

var _time_passed: float = 0.0

# --- BARU: data lock-on ---
var _player: Node2D
var _min_track_y: float
var _max_track_y: float
var _finalize_callback: Callable
var _extra_travel_time: float = 0.0
var _tracking_lag: float = 4.0  # makin kecil = makin "lengket" mengikuti pemain (kurang akurat)


func _ready() -> void:
	set_deferred("monitoring", false)
	body_entered.connect(_on_body_entered)
	_enter_state(State.WARNING)

# Dipanggil spawner sebelum WARNING dimulai, agar rocket tahu siapa yang ditarget
func initialize_lock_on(player: Node2D, min_track_y: float, max_track_y: float, finalize_callback: Callable, extra_travel_time: float, tracking_inaccuracy: float) -> void:
	_player = player
	_min_track_y = min_track_y
	_max_track_y = max_track_y
	_finalize_callback = finalize_callback
	_extra_travel_time = extra_travel_time
	# inaccuracy makin besar -> lag makin terasa -> reticle makin "telat" ngejar pemain
	_tracking_lag = base_lock_on_speed / (1.0 + tracking_inaccuracy * 0.1)

func _process(delta: float) -> void:
	_time_passed += delta
	
	match current_state:
		State.WARNING:
			warning_sprite.modulate.a = 0.5 + (sin(_time_passed * telegraph_speed) * 0.5)
			
			if _player:
				var target_y: float = clamp(_player.global_position.y, _min_track_y, _max_track_y)
				global_position.y = lerp(global_position.y, target_y, _tracking_lag * delta)
				print("lag=%.4f weight=%.5f gap=%.1f" % [_tracking_lag, _tracking_lag * delta, target_y - global_position.y])
			else:
				print("WARNING: _player belum di-set!")
			
		State.LAUNCHING:
			position.x -= GameManager.current_world_speed * launch_speed * delta

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.WARNING:
			rocket_sprite.hide()
			warning_sprite.show()
			
			await get_tree().create_timer(warning_duration).timeout
			
			# --- BARU: kunci posisi final tepat sebelum meluncur ---
			if _finalize_callback.is_valid():
				var candidate_y: float = global_position.y  # hasil tracking terakhir
				var locked_y: float = _finalize_callback.call(candidate_y, _min_track_y, _max_track_y, _extra_travel_time)
				global_position.y = locked_y
			
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

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
