extends Area2D

@onready var ray_cast = $RayCast2D
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

const SPRITE_NATIVE_WIDTH = 32.0 

func _ready():
	# Karena root node (Area2D) sudah dirotasi oleh senjata, 
	# RayCast2D otomatis akan menembak ke arah sudut yang benar!
	ray_cast.force_raycast_update()
	
	var beam_length: float
	
	if ray_cast.is_colliding():
		var collision_point = ray_cast.get_collision_point()
		beam_length = global_position.distance_to(collision_point)
	else:
		# Menyesuaikan panjang maksimum sesuai target_position RayCast
		beam_length = ray_cast.target_position.x

	# Meregangkan visual (Sprite)
	var required_scale_x = beam_length / SPRITE_NATIVE_WIDTH
	sprite.scale.x = required_scale_x
	
	# Meregangkan dan memposisikan collision (Area2D)
	var shape = collision_shape.shape.duplicate() as RectangleShape2D
	
	if shape:
		shape.size.x = beam_length
		collision_shape.position.x = beam_length / 2
	# Terapkan shape yang sudah diduplikat dan diubah ukurannya kembali ke node
		collision_shape.shape = shape 
		force_update_transform()
	else:
		# Ini akan muncul di panel Output jika Anda salah memilih bentuk di Inspector
		print("ERROR: Bentuk collision bukan RectangleShape2D!")	# Hancurkan laser setelah 0.1 detik
	await get_tree().create_timer(0.1).timeout
	queue_free()

# FUNGSI set_direction() SUDAH DIHAPUS
