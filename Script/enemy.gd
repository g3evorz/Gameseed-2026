extends Node2D

## State machine musuh:
## - ENTRANCE: kemunculan pertama musuh di scene, cepat & dramatis (cinematic).
## - LURKING: musuh diam/menunggu di tepi layar, belum terlihat menyerang.
## - OVERTAKE: musuh mendahului pemain menuju titik drop.
## - DROPPING: musuh menjatuhkan rintangan di titik drop.
## - COOLDOWN: musuh kembali mundur ke area lurking, lalu mengulang siklus.
enum State { ENTRANCE, LURKING, OVERTAKE, DROPPING, COOLDOWN }

var current_state: State = State.ENTRANCE

signal obstacle_dropped(drop_position: Vector2)

# --- Variabel dasar pergerakan ---

## Posisi X "standar" musuh, jadi acuan saat musuh tidak sedang di-tween ke posisi lain.
var base_x_position: float

## Posisi Y "standar" musuh, jadi titik tengah dari gelombang hover (sine wave).
var base_y_position: float

## Seberapa cepat musuh melayang naik-turun (semakin besar, semakin cepat getarannya).
@export var hover_speed: float = 2.0

## Seberapa jauh musuh melayang naik-turun dari posisi standarnya (dalam pixel).
@export var hover_amplitude: float = 8.0

# --- Variabel state machine ---

@export var entrance_offset: float = 2500.0

@export var entrance_duration: float = 15.0

var _entrance_start_x: float

@export var overtake_offset: float = 700.0

@export var drop_hold_time: float = 3.5

var _lurk_x: float
var _drop_x: float

var _lurk_timer: Timer

var _time_passed: float = 0.0

var _move_tween: Tween

func _ready() -> void:
	base_x_position = position.x
	base_y_position = position.y

	_lurk_x = base_x_position
	_drop_x = base_x_position + overtake_offset

	var overtake_direction: float = sign(overtake_offset) if overtake_offset != 0.0 else 1.0
	_entrance_start_x = _lurk_x - overtake_direction * entrance_offset

	_lurk_timer = Timer.new()
	_lurk_timer.one_shot = true
	add_child(_lurk_timer)
	_lurk_timer.timeout.connect(_on_lurk_timer_timeout)

	_enter_state(State.ENTRANCE)

func _process(delta: float) -> void:
	_time_passed += delta

	position.y = base_y_position + sin(_time_passed * hover_speed) * hover_amplitude

	match current_state:
		State.ENTRANCE:
			pass # Pergerakan ditangani oleh Tween dari move_to_x(); tidak perlu logika tiap frame.
		State.LURKING:
			pass # Diam menunggu; _lurk_timer yang akan memicu pindah ke OVERTAKE.
		State.OVERTAKE:
			pass # Pergerakan ditangani oleh Tween dari move_to_x(); tidak perlu logika tiap frame.
		State.DROPPING:
			pass # State ini transisional, ditangani sepenuhnya di _enter_state().
		State.COOLDOWN:
			pass # Pergerakan ditangani oleh Tween dari move_to_x(); tidak perlu logika tiap frame.


func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	var diff = GameManager.current_difficulty
	
	match current_state:
		State.ENTRANCE:
			# Kemunculan pertama: posisikan musuh jauh di belakang dulu...
			position.x = _entrance_start_x
			base_x_position = _entrance_start_x

			move_to_x(
				_lurk_x, entrance_duration,
				func() -> void: _enter_state(State.LURKING),
				Tween.TRANS_BACK, Tween.EASE_OUT
			)

		State.LURKING:
			# Diam/menetap di tepi layar (posisi lurking).
			position.x = _lurk_x
			base_x_position = _lurk_x

			# Mulai timer acak sebelum musuh mulai menyerang lagi.
			_lurk_timer.wait_time = randf_range(diff.lurk_time_min, diff.lurk_time_max)
			_lurk_timer.start()

		State.OVERTAKE:
			move_to_x(
				_drop_x, diff.overtake_duration,
				func() -> void: _enter_state(State.DROPPING),
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
			)

		State.DROPPING:
			_drop_obstacle()
			
			await get_tree().create_timer(drop_hold_time).timeout
			_enter_state(State.COOLDOWN)

		State.COOLDOWN:
			move_to_x(
				_lurk_x, diff.cooldown_duration,
				func() -> void: _enter_state(State.LURKING),
				Tween.TRANS_QUAD, Tween.EASE_IN_OUT
			)


func _on_lurk_timer_timeout() -> void:
	_enter_state(State.OVERTAKE)


func _drop_obstacle() -> void:
	obstacle_dropped.emit(global_position)

func move_to_x(
	target_x: float,
	duration: float,
	on_finished: Callable = Callable(),
	trans: Tween.TransitionType = Tween.TRANS_SINE,
	ease: Tween.EaseType = Tween.EASE_IN_OUT
) -> void:

	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position:x", target_x, duration)\
		.set_trans(trans)\
		.set_ease(ease)

	if on_finished.is_valid():
		_move_tween.finished.connect(on_finished, CONNECT_ONE_SHOT)

	base_x_position = target_x
