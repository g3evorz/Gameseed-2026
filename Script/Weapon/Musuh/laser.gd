extends Node2D

enum State { ENGAGING, WARNING, LAUNCH, RETACKING }
var current_state: State = State.ENGAGING

@export var bullet_scene: PackedScene
@export var damage_laser: float = 9999999.0

var engaging_duration: float = 1.0   # durasi laser bergerak dari start -> target
var warning_duration: float = 2.0    # durasi telegraph diam di posisi akhir sebelum nembak
var telegraph_speed: float = 25.0
var fire_duration: float = 0.5
var retreat_duration: float = 1.0    # durasi laser mundur keluar arena
var retreat_distance: float = 300.0  # seberapa jauh laser mundur (ke arah +X)

# Variabel untuk pergerakan dinamis
var _start_position: Vector2
var _target_position: Vector2
var _retreat_start_position: Vector2
var _retreat_position: Vector2
var _is_moving: bool = false
var _time_passed: float = 0.0

var _cam: Camera2D
var _edge_margin: float = 0.0

@export var entrance_offset_x: float = 300.0

@onready var warning_indicator = $WarningIndicator
@onready var satellite_body = $SatelliteSprite
@onready var muzzle = $Muzzle

func _ready() -> void:
	_enter_state(State.ENGAGING)

# Fungsi ini dipanggil oleh Spawner untuk menentukan jalur pergerakan laser
func setup_dynamic_laser(posisi_awal: Vector2, posisi_akhir: Vector2, durasi: float, cam: Camera2D, edge_margin: float) -> void:
	_start_position = posisi_awal
	_target_position = posisi_akhir
	engaging_duration = durasi
	_cam = cam
	_edge_margin = edge_margin
	global_position = _start_position
	_is_moving = true

# Helper: re-anchor X tiap frame supaya laser tetap "menempel" di tepi layar
# meski kamera terus bergerak (dipakai selama fase ENGAGING & WARNING)
func _get_anchored_x() -> float:
	if _cam:
		return _cam.get_right_edge_x(_edge_margin)
	return global_position.x

func _process(delta: float) -> void:
	match current_state:
		State.ENGAGING:
			_time_passed += delta
			#warning_indicator.modulate.a = 0.5 + (sin(_time_passed * telegraph_speed) * 0.5) # EFEK NGEBLINK
 
			var anchored_x: float = _get_anchored_x()
 
			if _is_moving and engaging_duration > 0:
				var progress = clamp(_time_passed / engaging_duration, 0.0, 1.0)
				var eased_progress = ease(progress, -1.5)
 
				# Entrance X: mulai dari luar layar (anchored_x + offset, ke arah kanan)
				# lalu slide masuk menuju anchored_x seiring progress.
				var x = anchored_x + entrance_offset_x * (1.0 - eased_progress)
 
				# Tracking Y tetap dinamis seperti semula (lock-on ke posisi target).
				var y = lerp(_start_position.y, _target_position.y, eased_progress)
				global_position = Vector2(x, y)
			else:
				global_position = Vector2(anchored_x, _target_position.y)
 
			if _time_passed >= engaging_duration:
				_enter_state(State.WARNING)
 


		State.WARNING:
			_time_passed += delta
			warning_indicator.modulate.a = 0.5 + (sin(_time_passed * telegraph_speed) * 0.5)

			# Posisi Y sudah final dari ENGAGING, tinggal jaga X tetap nempel di edge kamera
			global_position = Vector2(_get_anchored_x(), _target_position.y)

			if _time_passed >= warning_duration:
				_enter_state(State.LAUNCH)

		State.LAUNCH:
			# Laser emitter diam di posisi terakhirnya saat menembak
			pass

		State.RETACKING:
			_time_passed += delta
			var progress = clamp(_time_passed / retreat_duration, 0.0, 1.0)
			var eased_progress = ease(progress, 1.5)
			global_position = _retreat_start_position.lerp(_retreat_position, eased_progress)

			if _time_passed >= retreat_duration:
				queue_free()

func _enter_state(new_state: State) -> void:
	current_state = new_state
	_time_passed = 0.0 # Reset waktu untuk memastikan sinkronisasi tiap pergantian state

	match current_state:
		State.ENGAGING:
			warning_indicator.hide()
			satellite_body.show()

		State.WARNING:
			warning_indicator.show()

		State.LAUNCH:
			warning_indicator.hide()

			# Gunakan posisi muzzle (jika tersedia) agar tembakan keluar dari laras
			var posisi_tembak = muzzle.global_position if muzzle else global_position
			var arah_target = posisi_tembak + Vector2(-2000, 0)

			_spawn_laser_ke_target(posisi_tembak, arah_target)

			# Tunggu sebentar sebelum mundur agar pulseBullet punya waktu untuk dieksekusi
			await get_tree().create_timer(fire_duration + 2).timeout
			_enter_state(State.RETACKING)

		State.RETACKING:
			satellite_body.show()
			_retreat_start_position = global_position
			_retreat_position = global_position + Vector2(retreat_distance, 0)

func _spawn_laser_ke_target(posisi_spawn: Vector2, posisi_target: Vector2) -> void:
	if not bullet_scene:
		print("ERROR: bullet_scene kosong di laser.gd!")
		return
		
	var bullet = bullet_scene.instantiate()
	var damage: float = damage_laser
	
	get_tree().current_scene.add_child(bullet) 
	
	bullet.global_position = posisi_spawn
	
	var direction = (posisi_target - posisi_spawn).normalized()
	bullet.beam_active_duration = fire_duration   # samakan dengan host
	bullet.fire(direction,damage)
