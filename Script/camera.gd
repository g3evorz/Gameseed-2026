extends Camera2D

@export_group("Dynamic Offset")
@export var default_offset_x: float = 0.0
@export var max_lag_offset_x: float = 1000.0

@export_group("Dynamic Zoom")
@export var default_zoom: Vector2 = Vector2(0.6, 0.6)
@export var max_fast_zoom: Vector2 = Vector2(0.4, 0.4)

@export_group("Smoothing Dynamics")
@export var max_smoothing: float = 8.0 
@export var min_smoothing: float = 2.0 
@export var transition_speed: float = 4.0 

@export_group("Wobble / Shake Effect")
@export var wobble_amplitude: float = 15.0 
@export var wobble_speed: float = 20.0 
@export var wobble_active_duration: float = 0.5 
@export var wobble_pause_duration: float = 1.5

@export_group("Hit Stop Shake")
@export var hit_shake_intensity: float = 15.0 # Seberapa kuat getarannya (dalam piksel)
@export var hit_shake_decay: float = 15.0 # Kecepatan kamera kembali tenang setelah hit stop

var _current_active_smoothing: float = 8.0
var _fixed_global_y: float = 0.0
var _time_passed: float = 0.0 # Waktu berjalan untuk fungsi gelombang sinus

# Variabel internal untuk Wobble Interval
var _wobble_state_timer: float = 0.0
var _is_wobbling_active: bool = false
var _wobble_weight: float = 0.0 # Transisi mulus antara goyang dan diam

func _ready():
	top_level = true
	_fixed_global_y = global_position.y
	_current_active_smoothing = max_smoothing

func _physics_process(delta):
	_time_passed += delta
	_wobble_state_timer += delta
	
	if not has_node("/root/GameManager"):
		return

	var current_speed = GameManager.current_world_speed
	var max_speed = GameManager.MAX_SPEED
	var base_speed = GameManager.BASE_SPEED
	
	if max_speed == base_speed:
		max_speed += 1.0 
	
	var speed_ratio = clamp((current_speed - base_speed) / (max_speed - base_speed), 0.0, 1.0)
	
	# --- SISTEM INTERVAL WOBBLE ---
	if _is_wobbling_active:
		if _wobble_state_timer >= wobble_active_duration:
			_is_wobbling_active = false
			_wobble_state_timer = 0.0
	else:
		if _wobble_state_timer >= wobble_pause_duration:
			_is_wobbling_active = true
			_wobble_state_timer = 0.0
			
	# Transisi mulus (lerp) agar kamera tidak patah saat wobble menyala/mati
	var target_wobble_weight = 1.0 if _is_wobbling_active else 0.0
	_wobble_weight = lerp(_wobble_weight, target_wobble_weight, 5.0 * delta)
	
	# Kalkulasi getaran (hanya terpicu kuat di kecepatan tinggi karena dipangkatkan 3)
	var intensity = pow(speed_ratio, 3) 
	var raw_wobble_offset = sin(_time_passed * wobble_speed) * wobble_amplitude * intensity
	
	# Kalikan hasil wobble dengan weight intervalnya
	var final_wobble_offset = raw_wobble_offset * _wobble_weight
	# ------------------------------
	
	var target_offset_x = lerp(default_offset_x, max_lag_offset_x, speed_ratio)
	var target_x = get_parent().global_position.x + target_offset_x + final_wobble_offset
	
	var target_zoom = lerp(default_zoom, max_fast_zoom, speed_ratio)
	var target_smoothing = lerp(max_smoothing, min_smoothing, speed_ratio)
	
	var current_transition = transition_speed
	# --- LOGIKA KETIKA HIT STOP AKTIF ---
	if GameManager.is_hit_stopping:
		current_transition *= 3.0 
		
		# Hasilkan angka acak (X dan Y) secara liar untuk efek getaran tabrakan
		var shake_x = randf_range(-hit_shake_intensity, hit_shake_intensity)
		var shake_y = randf_range(-hit_shake_intensity, hit_shake_intensity)
		
		# Gunakan properti 'offset' bawaan Camera2D agar tidak merusak perhitungan global_position
		self.offset = Vector2(shake_x, shake_y)
	else:
		# Jika tidak hit_stop, kembalikan offset ke 0 secara perlahan (mulus)
		self.offset = self.offset.lerp(Vector2.ZERO, hit_shake_decay * delta)
		
	_current_active_smoothing = lerp(_current_active_smoothing, target_smoothing, current_transition * delta)
	
	var new_x = lerp(global_position.x, target_x, _current_active_smoothing * delta)
	global_position = Vector2(new_x, _fixed_global_y)
	
	zoom = lerp(zoom, target_zoom, _current_active_smoothing * delta)
