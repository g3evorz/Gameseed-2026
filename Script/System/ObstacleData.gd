class_name ObstacleData
extends Resource

# Mendefinisikan tipe rintangan menggunakan enum
enum ObstacleType { SMALL, BIG, ROCKET }

# Variabel yang akan diekspos ke Inspector
@export var obstacle_scene: PackedScene
@export var spawn_weight: float = 1.0
@export var obstacle_type: ObstacleType = ObstacleType.SMALL
@export var max_hp: int = 10
