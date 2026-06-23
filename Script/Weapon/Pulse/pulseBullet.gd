extends Area2D

@onready var ray_cast = $RayCast2D
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

const SPRITE_NATIVE_WIDTH = 32.0 

# UBAH NAMA FUNGSI INI DARI _ready() MENJADI fire()
func fire():
	ray_cast.force_raycast_update()
	
	var beam_length: float
	
	if ray_cast.is_colliding():
		var collision_point = ray_cast.get_collision_point()
		beam_length = global_position.distance_to(collision_point)
		
		var musuh = ray_cast.get_collider()
		
		if musuh.has_method("take_damage"):
			musuh.take_damage(ScoreManager.level_upgrade_laser * 10)
		else:
			print("Nabrak tembok/benda mati, abaikan.")
	else:
		beam_length = ray_cast.target_position.x

	var required_scale_x = beam_length / SPRITE_NATIVE_WIDTH
	sprite.scale.x = required_scale_x
	
	var shape = collision_shape.shape.duplicate() as RectangleShape2D
	
	if shape:
		shape.size.x = beam_length
		collision_shape.position.x = beam_length / 2
		collision_shape.shape = shape 
		force_update_transform()
	else:
		print("ERROR: Bentuk collision bukan RectangleShape2D!")	

	await get_tree().create_timer(0.1).timeout
	queue_free()
