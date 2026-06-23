extends Camera2D

@export_category("Camera Settings")
@export var target: Node2D

@export_group("Smoothing Dynamics")
@export var max_smoothing: float = 10.0 
@export var min_smoothing: float = 2.0 
@export var speed_threshold: float = 400.0 
## Kecepatan transisi smoothing (Semakin kecil nilainya, semakin mulus/lembut efek berhentinya)
@export var transition_speed: float = 4.0 

var _last_target_x: float = 0.0
var _fixed_y: float = 0.0
var _current_active_smoothing: float = 10.0 # Menyimpan nilai smoothing yang sedang berjalan

func _ready():
	top_level = true 
	position_smoothing_enabled = false
	
	if target:
		_last_target_x = target.global_position.x
		global_position.x = _last_target_x
		
	_fixed_y = global_position.y
	_current_active_smoothing = max_smoothing

func _physics_process(delta):
	if not target:
		return
		
	var current_target_x = target.global_position.x
	var speed_x = abs(current_target_x - _last_target_x) / delta
	_last_target_x = current_target_x

	var speed_ratio = clamp(speed_x / speed_threshold, 0.0, 1.0)
	var target_smoothing = lerp(max_smoothing, min_smoothing, speed_ratio)

	_current_active_smoothing = lerp(_current_active_smoothing, target_smoothing, transition_speed * delta)
	
	var new_x = lerp(global_position.x, current_target_x, _current_active_smoothing * delta)

	global_position = Vector2(new_x, _fixed_y)
