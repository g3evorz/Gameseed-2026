extends Area2D

@onready var ray_cast = $RayCast2D
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

const SPRITE_NATIVE_WIDTH = 32.0

@export var beam_active_duration: float = 0.1   
@export var damage_tick_rate: float = 0.1 # Interval waktu damage diberikan (contoh: 0.1 detik)
@export var kekuatan_slow: float = 0.7 

var _current_damage: float = 0.0
var _dir_multiplier: float = 1.0
var _tick_timer: float = 0.0
var _is_firing: bool = false

func _ready() -> void:
	# Matikan process agar tidak menguras performa sebelum fire() dipanggil
	set_physics_process(false)
	
	# Lakukan duplikasi shape satu kali saja di awal 
	if collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate() as RectangleShape2D

func fire(direction: Vector2, damage: float) -> void:
	_current_damage = damage
	_dir_multiplier = sign(direction.x) if direction.x != 0.0 else 1.0
	
	var max_range = abs(ray_cast.target_position.x)
	ray_cast.target_position.x = max_range * _dir_multiplier
	ray_cast.collide_with_areas = true
	
	_is_firing = true
	_tick_timer = damage_tick_rate # Di-set penuh agar damage pertama langsung berefek
	
	# Nyalakan loop physics process
	set_physics_process(true)
	
	# Hancurkan peluru setelah durasi habis
	await get_tree().create_timer(beam_active_duration).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if not _is_firing:
		return
		
	_tick_timer += delta
	
	# Update raycast secara manual tiap physics frame
	ray_cast.force_raycast_update()
	
	var max_range = abs(ray_cast.target_position.x)
	var beam_length: float = max_range
	var hit_target = null
	
	if ray_cast.is_colliding():
		var collision_point = ray_cast.get_collision_point()
		beam_length = global_position.distance_to(collision_point)
		hit_target = ray_cast.get_collider()
	
	# 1. Update Skala Visual
	var required_scale_x = beam_length / SPRITE_NATIVE_WIDTH
	sprite.scale.x = required_scale_x
	sprite.position.x = (beam_length / 2.0) * _dir_multiplier
	
	# 2. Update Collision Shape Size secara dinamis
	var shape = collision_shape.shape as RectangleShape2D
	if shape:
		shape.size.x = beam_length 
		collision_shape.position.x = (beam_length / 2.0) * _dir_multiplier 
	
	# 3. Handle Damage (Sistem Tick)
	if _tick_timer >= damage_tick_rate:
		_tick_timer -= damage_tick_rate # Kurangi timer, jangan reset ke 0 agar tidak meleset
		
		if hit_target:
			if hit_target.has_method("take_damage"):
				hit_target.take_damage(_current_damage)
			elif hit_target.get_parent().is_in_group("Player") and hit_target.get_parent().has_method("take_damage"):
				hit_target.get_parent().take_damage(_current_damage)
				GameManager.terapkan_efek_ram(kekuatan_slow)
