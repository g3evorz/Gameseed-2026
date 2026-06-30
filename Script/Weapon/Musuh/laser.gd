extends Node2D

enum State { WARNING, LAUNCH }
var current_state: State = State.WARNING

@export var bullet_scene: PackedScene

var warning_duration: float = 2.0
var telegraph_speed: float = 25.0
var fire_duration: float = 0.5 

# Variabel untuk pergerakan dinamis
var _start_position: Vector2
var _target_position: Vector2
var _is_moving: bool = false
var _time_passed: float = 0.0

var _cam: Camera2D
var _edge_margin: float = 0.0

@onready var warning_indicator = $WarningIndicator
@onready var satellite_body = $SatelliteSprite
@onready var muzzle = $Muzzle

func _ready() -> void:
	_enter_state(State.WARNING)

# Fungsi ini dipanggil oleh Spawner untuk menentukan jalur pergerakan laser
func setup_dynamic_laser(posisi_awal: Vector2, posisi_akhir: Vector2, durasi: float, cam: Camera2D, edge_margin: float) -> void:
	_start_position = posisi_awal
	_target_position = posisi_akhir
	warning_duration = durasi
	_cam = cam
	_edge_margin = edge_margin
	global_position = _start_position
	_is_moving = true

func _process(delta: float) -> void:
	match current_state:
		State.WARNING:
			_time_passed += delta
			warning_indicator.modulate.a = 0.5 + (sin(_time_passed * telegraph_speed) * 0.5)

			# Re-anchor X tiap frame supaya laser tetap "menempel" di tepi layar
			# meski kamera terus bergerak selama fase warning
			var current_x: float = global_position.x
			if _cam:
				current_x = _cam.get_right_edge_x(_edge_margin)

			if _is_moving and warning_duration > 0:
				var progress = clamp(_time_passed / warning_duration, 0.0, 1.0)
				var eased_progress = ease(progress, -1.5)
				var y = lerp(_start_position.y, _target_position.y, eased_progress)
				global_position = Vector2(current_x, y)
			else:
				global_position.x = current_x

			if _time_passed >= warning_duration:
				_enter_state(State.LAUNCH)
		State.LAUNCH:
			# Laser emitter diam di posisi terakhirnya saat menembak
			pass

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.WARNING:
			warning_indicator.show()
			satellite_body.show()
			_time_passed = 0.0 # Reset waktu untuk memastikan sinkronisasi
			
		State.LAUNCH:
			warning_indicator.hide()
			
			# PERBAIKAN: Gunakan posisi muzzle (jika tersedia) agar tembakan keluar dari laras
			var posisi_tembak = muzzle.global_position if muzzle else global_position
			var arah_target = posisi_tembak + Vector2(-2000, 0)
			
			print("Laser host position: ", global_position)
			print("Muzzle local position: ", muzzle.position)
			print("Muzzle global position: ", muzzle.global_position)
			
			_spawn_laser_ke_target(posisi_tembak, arah_target)
			
			# Tunggu sebentar sebelum menghapus spawner agar pulseBullet punya waktu untuk dieksekusi
			await get_tree().create_timer(fire_duration).timeout
			queue_free()

func _spawn_laser_ke_target(posisi_spawn: Vector2, posisi_target: Vector2) -> void:
	if not bullet_scene:
		print("ERROR: bullet_scene kosong di laser.gd!")
		return
		
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet) 
	
	bullet.global_position = posisi_spawn
	
	var direction = (posisi_target - posisi_spawn).normalized()
	bullet.beam_active_duration = fire_duration   # samakan dengan host
	bullet.fire(direction)
