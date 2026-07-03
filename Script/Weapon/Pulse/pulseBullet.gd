extends Area2D

@onready var ray_cast = $RayCast2D
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

const SPRITE_NATIVE_WIDTH = 32.0

enum BeamType {
	FAST,   # raycast sekali, damage instan, langsung queue_free — untuk senjata cepat
	SUSTAINED  # area overlap, damage berkelanjutan, aktif selama fire_duration — untuk choke point
}

@export var beam_type: BeamType = BeamType.FAST
@export var beam_active_duration: float = 0.5
@export var damage_tick_interval: float = 0.1

var _damage: float = 0.0
var _dir_multiplier: float = -1.0

func fire(direction: Vector2 = Vector2.RIGHT, damage: float = 100.0) -> void:
	_damage = damage
	_dir_multiplier = sign(direction.x) if direction.x != 0.0 else 1.0

	var max_range = abs(ray_cast.target_position.x)
	ray_cast.target_position.x = max_range * _dir_multiplier
	ray_cast.force_raycast_update()

	# Hitung beam_length di sini — sama untuk FAST maupun SUSTAINED
	var beam_length: float
	if ray_cast.is_colliding():
		beam_length = global_position.distance_to(ray_cast.get_collision_point())
	else:
		beam_length = max_range

	# Apply visual SEBELUM branching — keduanya butuh ini
	_apply_visual(beam_length)

	match beam_type:
		BeamType.FAST:
			AudioManager.putar_sfx(AudioManager.player_laser)
			if ray_cast.is_colliding():
				var target = ray_cast.get_collider()
				if target.has_method("take_damage"):
					target.take_damage(damage)
			await get_tree().create_timer(beam_active_duration).timeout
			queue_free()

		BeamType.SUSTAINED:
			AudioManager.putar_sfx(AudioManager.enemy_laser_launched)
			body_entered.connect(_on_body_entered)
			var elapsed: float = 0.0
			while elapsed < beam_active_duration:
				await get_tree().create_timer(damage_tick_interval).timeout
				elapsed += damage_tick_interval
				_tick_damage_inside()
			queue_free()

# Dipanggil LANGSUNG saat player pertama kali menyentuh beam — tidak ada delay
func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(_damage)

func _on_area_entered(area: Node) -> void:
	if area.has_method("take_damage"):
		area.take_damage(_damage)

# Dipanggil tiap tick untuk player yang SUDAH BERADA di dalam beam
func _tick_damage_inside() -> void:
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(_damage)
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(_damage)

func _apply_visual(beam_length: float) -> void:
	var required_scale_x = beam_length / SPRITE_NATIVE_WIDTH
	sprite.scale.x = required_scale_x
	sprite.position.x = (beam_length / 2.0) * _dir_multiplier

	var shape = collision_shape.shape.duplicate() as RectangleShape2D
	if shape:
		shape.size.x = beam_length
		collision_shape.position.x = (beam_length / 2.0) * _dir_multiplier
		collision_shape.shape = shape
		force_update_transform()
	else:
		print("ERROR: Bentuk collision bukan RectangleShape2D!")
