extends Area2D

@onready var ray_cast = $RayCast2D
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

const SPRITE_NATIVE_WIDTH = 32.0
@export var beam_active_duration: float = 0.1   # bisa di-override dari luar (laser.gd) atau diatur manual di Inspector kalau dipakai standalone

func fire(direction: Vector2 = Vector2.RIGHT) -> void:
	var dir_multiplier = sign(direction.x) if direction.x != 0.0 else 1.0
	var max_range = abs(ray_cast.target_position.x)
	ray_cast.target_position.x = max_range * dir_multiplier

	ray_cast.collide_with_areas = true
	ray_cast.force_raycast_update()

	var beam_length: float

	if ray_cast.is_colliding():
		var collision_point = ray_cast.get_collision_point()
		beam_length = global_position.distance_to(collision_point)

		var musuh = ray_cast.get_collider()
		var damage_pulse = ScoreManager.level_upgrade_laser * 10

		if musuh.has_method("take_damage"):
			musuh.take_damage(damage_pulse)
		else:
			print("Nabrak tembok/benda mati/Area lain, abaikan.")
	else:
		beam_length = max_range

	var required_scale_x = beam_length / SPRITE_NATIVE_WIDTH
	sprite.scale.x = required_scale_x
	sprite.position.x = (beam_length / 2.0) * dir_multiplier

	var shape = collision_shape.shape.duplicate() as RectangleShape2D

	if shape:
		shape.size.x = beam_length
		collision_shape.position.x = (beam_length / 2.0) * dir_multiplier
		collision_shape.shape = shape
		
		print("shape size : ", collision_shape.shape.size.x)
		
		force_update_transform()
	else:
		print("ERROR: Bentuk collision bukan RectangleShape2D!")

	await get_tree().create_timer(beam_active_duration).timeout
	queue_free()
